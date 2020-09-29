Param (
    [parameter(Mandatory=$false)]
    [String]$os="windows"
)

aws s3 cp s3://ctm-ami/${os}_base/latest.json ami_info.json
$ami_id=(Select-String -Path ".\ami_info.json"  -Pattern '\"eu-west-1\":\"(.*)\"').Matches.Groups[1].Value.Split(",")[0].TrimEnd('\"')

switch($os)
{
    "windows" 
    {
        Write-Output "##teamcity[setParameter name='env.TF_VAR_image_id' value='$ami_id']"
    }
    "linux"
    {
        Write-Output "##teamcity[setParameter name='env.TF_VAR_host_image_id' value='$ami_id']"
    }
}

Remove-Item ".\ami_info.json"
