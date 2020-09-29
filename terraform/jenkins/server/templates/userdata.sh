#!/bin/bash

UBUNTU_HOME="/home/ubuntu"

# Create Jenkins folders
mkdir $UBUNTU_HOME/jenkins
mkdir $UBUNTU_HOME/jenkins-backup

# Go to the jenkins folder
cd $UBUNTU_HOME/jenkins

# Update package sources
add-apt-repository ppa:openjdk-r/ppa
apt-get update

# Sleep - to avoid a race condition
sleep 10

# Install java
apt-get install openjdk-8-jre -y
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre/

# Install docker
apt-get -y install docker.io 

# Install Jenkins
docker network create jenkins

docker volume create jenkins-docker-certs
docker volume create jenkins-data

docker container run --name jenkins-docker --rm --detach --privileged --network jenkins --network-alias docker --env DOCKER_TLS_CERTDIR=/certs --volume jenkins-docker-certs:/certs/client --volume jenkins-data:/var/jenkins_home --publish 2376:2376 docker:dind

docker container run --name jenkins-blueocean --rm --detach --network jenkins --env DOCKER_HOST=tcp://docker:2376 --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 --publish 8080:8080 --publish 50000:50000 --volume jenkins-data:/var/jenkins_home --volume jenkins-docker-certs:/certs/client:ro jenkinsci/blueocean

# Install git
apt-get install git

# Install zip
apt install zip

# Update locale
locale-gen en_GB.UTF-8
update-locale LANG=en_GB.UTF-8

# Set the time
timedatectl set-timezone Europe/London

RESTORE_LOGFILE=$UBUNTU_HOME/jenkins-backup/restore_$(date '+%Y%m%d_%H%M').log

# Redirect all output to the log file, including errors
exec > $RESTORE_LOGFILE 2>&1

echo "# Impersonating terraform role"
# FETCH LATEST BACKUP FROM AWS
# ===================================================================
# Impersonate the terraform role to access AWS S3
# ===================================================================
role_arn='arn:aws:iam::482506117024:role/terraform'

temp_role=$(aws sts assume-role --role-arn $role_arn --role-session-name mit-ci_role_assume_ctm-mit --region eu-west-1)

export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq -r .Credentials.SessionToken)

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set aws_session_token $AWS_SESSION_TOKEN
# ===================================================================

# Get the name of the lastest backup file
BACKUP_FILE=$(aws s3 ls --human-readable --summarize s3://mit-ci-artifacts/backups/jenkins-backup_ | grep -ho "jenkins-backup_\w*.zip\w*" | sort -r | head -1)
echo "# Latest backup file: $BACKUP_FILE"

# download latest backup file
echo "# download file"
aws s3 cp s3://mit-ci-artifacts/backups/$BACKUP_FILE $UBUNTU_HOME/jenkins

# Unzip backup
echo "# Unzip file"
unzip $UBUNTU_HOME/jenkins/$BACKUP_FILE -d $UBUNTU_HOME/jenkins > /dev/null

# wait for jenkins to start up (up to 10 mins, it usually takes 1 or 2 mins)
echo "# Waiting for Jenkins to start"
tries=0
jenkins_is_alive=false
while [ $tries -le 10 ] && [ "$jenkins_is_alive" = false ]
do
  tries=$(( $tries + 1 ))
  status_code=$(curl -LI -o /dev/null -w '%%{http_code}\n' -s http://localhost:8080)

  if [ $status_code = 403 ]
  then
    jenkins_is_alive=true
  else
    sleep 1m
  fi

done

echo "# Waited for $tries minutes"

# Get default Admin Password
echo "# Get default Admin Password"
docker cp jenkins-blueocean:/var/jenkins_home/secrets/initialAdminPassword  $UBUNTU_HOME/jenkins 

ADMIN_PASSWORD=$(cat $UBUNTU_HOME/jenkins/initialAdminPassword)

# Get the Antiforgery token
echo "# Get antiforgery token"
TEMP_CRUMB_JSON=$(curl -c cookies.txt --user admin:$ADMIN_PASSWORD http://localhost:8080/crumbIssuer/api/json)
CRUMB=$(echo $TEMP_CRUMB_JSON | jq -r .crumb)
CRUMB_RQ_FIELD=$(echo $TEMP_CRUMB_JSON | jq -r .crumbRequestField)

# Make the ubuntu user own the folder instead of root
echo "# Grant permissions to the ubuntu user to the whole jenkins folder"
chown -R ubuntu:ubuntu $UBUNTU_HOME/jenkins

# Restore backup into current instance
# the dot copies the contents of the folder (recursively), without it, it would copy the folder and its contents.
echo "# Restore backup into current instance"
docker cp $UBUNTU_HOME/jenkins/jenkins-data/. jenkins-blueocean:/var/jenkins_home

# Do a safe Reset
echo "# Do a safe Reset"
curl -X POST -H $CRUMB_RQ_FIELD:$CRUMB -b cookies.txt --user admin:$ADMIN_PASSWORD http://localhost:8080/safeRestart

# Clean up
echo "# Clean up"
cd $UBUNTU_HOME
rm -r -f $UBUNTU_HOME/jenkins


# DONE!!!

# =========================================================================
# backup-generator.sh
# =========================================================================
cat >> $UBUNTU_HOME/jenkins-backup/backup-generator.sh <<EOF
#!/bin/bash

# Re-Create Jenkins folders
sudo mkdir $UBUNTU_HOME/jenkins
sudo mkdir $UBUNTU_HOME/jenkins/jenkins-data
cd $UBUNTU_HOME

BACKUP_LOGFILE=$UBUNTU_HOME/jenkins-backup/backup_\$(date '+%Y%m%d_%H%M').log

# Redirect all output to the log file, including errors
exec > \$BACKUP_LOGFILE 2>&1

# Copies data into backup folder
# the dot copies the contents of the folder (recursively), without it, it would copy the folder and its contents.
# -a if for archive so it also copies uids and gids
echo "# Coping data to the backup folder"
sudo docker cp -a jenkins-blueocean:/var/jenkins_home/. $UBUNTU_HOME/jenkins/jenkins-data/ 

# Add permissions to the secrets folder so we can remove unwanted files
echo "# adding permissions to secrets folder"
sudo chmod +srx $UBUNTU_HOME/jenkins/jenkins-data/secrets

# Remove unwanted files
echo "# removing unwanted files"
sudo rm $UBUNTU_HOME/jenkins/jenkins-data/identity.key.enc
sudo rm $UBUNTU_HOME/jenkins/jenkins-data/secrets/org.jenkinsci.main.modules.instance_identity.InstanceIdentity.KEY
sudo rm $UBUNTU_HOME/jenkins/jenkins-data/secrets/initialAdminPassword

# Remove old builds
# ------------------------------------------------------------------
BUILDS_TO_BE_RETAINED=22 # 20 folders + 2 files

for pipeline in \$(sudo ls $UBUNTU_HOME/jenkins/jenkins-data/jobs)
do
        echo ""
        echo "Pipeline: \$pipeline"
        echo "------------------------"
        
        TOTAL_BUILDS=\$(sudo ls $UBUNTU_HOME/jenkins/jenkins-data/jobs/\$pipeline/builds -1v | wc -l)
        echo "Total builds=\$TOTAL_BUILDS"
        
        if [[ \$TOTAL_BUILDS -gt \$BUILDS_TO_BE_RETAINED ]]
        then
                BUILDS_TO_BE_DELETED=\$((\$TOTAL_BUILDS-\$BUILDS_TO_BE_RETAINED))
        else
                BUILDS_TO_BE_DELETED=0
        fi

        echo "Builds to be deleted=\$BUILDS_TO_BE_DELETED"
        
        for build_folder in \$(sudo ls $UBUNTU_HOME/jenkins/jenkins-data/jobs/\$pipeline/builds -1v | head -\$BUILDS_TO_BE_DELETED)
        do
                echo "deleting \$build_folder"
                sudo rm -r -f $UBUNTU_HOME/jenkins/jenkins-data/jobs/\$pipeline/builds/\$build_folder
        done
done
# --------------------------------------------------------------------

# Create backup file (zip contents)
NEW_BACKUP_FILENAME="jenkins-backup_\$(date '+%Y%m%d_%H%M').zip"
echo "# Backup filename=\$NEW_BACKUP_FILENAME"  

# The line below will zip the contents of the jenkins-data folder with the folder included.
echo "# zipping files"
cd $UBUNTU_HOME/jenkins
sudo zip -r \$NEW_BACKUP_FILENAME ./jenkins-data > /dev/null

# Remove AWS credentials if they already exist (and suppress error trying to remove them if they don't exist)
echo "# removing aws credentials"
sudo rm -f $UBUNTU_HOME/.aws/credentials 2> /dev/null

# Impersonate the terraform role to access AWS S3
# ===================================================================
echo "# impersonating terraform role"
role_arn='arn:aws:iam::482506117024:role/terraform'

temp_role=\$(sudo aws sts assume-role --role-arn \$role_arn --role-session-name mit-ci_role_assume_ctm-mit --region eu-west-1)

export AWS_ACCESS_KEY_ID=\$(echo \$temp_role | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=\$(echo \$temp_role | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=\$(echo \$temp_role | jq -r .Credentials.SessionToken)

sudo aws configure set aws_access_key_id \$AWS_ACCESS_KEY_ID
sudo aws configure set aws_secret_access_key \$AWS_SECRET_ACCESS_KEY
sudo aws configure set aws_session_token \$AWS_SESSION_TOKEN
# ===================================================================

# Upload backup file
echo "# upload backup file"
sudo aws s3 cp $UBUNTU_HOME/jenkins/\$NEW_BACKUP_FILENAME s3://mit-ci-artifacts/backups/\$NEW_BACKUP_FILENAME

MIN_BACKUPS=3
TOTAL_BACKUPS=\$(sudo aws s3 ls s3://mit-ci-artifacts/backups/jenkins-backup_ | wc -l)
TOTAL_FILES_TO_BE_DELETED=\$((TOTAL_BACKUPS - MIN_BACKUPS))

echo "# Total backups=\$TOTAL_BACKUPS, total files to be deleted=\$TOTAL_FILES_TO_BE_DELETED"

while [ \$TOTAL_FILES_TO_BE_DELETED -ge 1 ] 
do
  FILE_TO_BE_DELETED=\$(sudo aws s3 ls s3://mit-ci-artifacts/backups/jenkins-backup_ | grep -ho "jenkins-backup_\w*.zip\w*" | sort -r | tail -1)
  echo "# File to be deleted: \$FILE_TO_BE_DELETED"
  sudo aws s3 rm s3://mit-ci-artifacts/backups/\$FILE_TO_BE_DELETED
  ((TOTAL_FILES_TO_BE_DELETED--))
done

 # Clean up
 echo "# remove jenkins folder"
 sudo rm -r -f $UBUNTU_HOME/jenkins

EOF

# Add execute permissions to backup-generator file
# and grant permissions to the backup folder to the ubuntu user
chmod +x $UBUNTU_HOME/jenkins-backup/backup-generator.sh
chown ubuntu:ubuntu $UBUNTU_HOME/jenkins-backup/backup-generator.sh
echo "# Add execute permissions to backup-generator file"
echo "# and grant permissions to the backup folder to the ubuntu user"

# Schedule daily backup task
# Create line for crontab. The extra line is needed, otherwise cron won't work.
# 0 19 * * 1-5  => Run every day Mon-Fri @19:00
echo "# Schedule backup"
CRONPATH="PATH=$PATH"
CRONLINE="0 19 * * 1-5 /bin/bash $UBUNTU_HOME/jenkins-backup/backup-generator.sh"

# The below will enter the lines at the bottom of the current users crontab file
(crontab -l -u ubuntu; echo "$CRONPATH") | crontab - -u ubuntu
(crontab -l -u ubuntu; echo "$CRONLINE") | crontab - -u ubuntu

# THE END
