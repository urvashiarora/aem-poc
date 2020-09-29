Param (
    [parameter(Mandatory=$true)]
    [String]$action
)


Function Run-Command([String] $Command) {
    # ===== RUN THE COMMAND AND RETRY IF THE AWS CREDENTIALS ERROR IS PRESENT
    $AwsCredsErrorRetries = 3
    $Tries = 1
  
    DO {
        $LastCommandErrors = $null
        Write-Host "running this: $Command, try #$Tries of $AwsCredsErrorRetries"
        Invoke-Expression "& $Command 2>''" -OutVariable LastCommandOutput -ErrorVariable LastCommandErrors
        $Tries++
    } while ((($LastCommandErrors -join '') -match "No valid credential sources found for AWS Provider") -and ($Tries -le $AwsCredsErrorRetries))
  
    # ===== IGNORING 'WORKSPACE ALREADY EXISTS' ERROR AS THIS IS SOMETIMES EXPECTED
    if (($LastCommandErrors -join '') -match "Workspace `"main`" already exists") {
        return
    }
  
    Write-Host "LastCommandErrors = $LastCommandErrors"
    Write-Host "Last Powershell Command = $?"
    # ===== ONCE THE ABOVE IS FINISHED, THE COMMAND EITHER PASSED OR CONTAINED A PERSISTENT ERROR, OR POWERSHELL FAILED
    if ($LastCommandErrors -or !$? ) {
        Write-Host "Something went wrong, see the output above"
        exit 1
    } else {
        return
    }
  }


$args = @()
$args += ($action)

# ===== ADD EXTRA FLAGS FOR CETAIN ACTIONS
if ($action -eq "apply")
{
    $args += ("--auto-approve")
} elseif ($action -eq "destroy") {
    $args += ("--force")
}


# ===== COLLECT INFORMATION FROM THE CONFIG FILE
$BUCKET="ctm-terraform"
$KEY="ci-jk-server.tfstate"

# ===== INITIALISE TERRAFORM WORKSPACE (points to the correct state file folder in the S3 bucket)
Run-Command("terraform init -backend-config='workspace_key_prefix=state/mit' -reconfigure")

# ===== SET THE TERRAFORM WORKSPACE
Write-Output "========== attempting to initialise a new terraform workspace"
Run-Command("terraform workspace new main")

Write-Output "========== selecting existing terraform workspace"
Run-Command("terraform workspace select main")

Write-Output "S3 State Path: s3://$BUCKET/state/mit/main/$KEY"

# ===== RUN THE TERRAFORM COMMAND
Run-Command("terraform $args")
