# ==== Module imports =====
if (!(Get-Module "RunCommand")) { Import-Module $PSScriptRoot\RunCommand.psm1 -Force }

# ===== Assume role with AWS =====
function Assume-Role {
    param (
        [parameter(Mandatory=$true)]
        [String]$account_number,

        [parameter(Mandatory=$true)]
        [String]$role
    )

    $arnResult = "arn:aws:iam::" + $account_number + ":role/" + $role

    $assumeCall = Run-Command("aws sts assume-role --role-arn=$arnResult --role-session-name mit-ci_role_assume_ctm-mit --region eu-west-1")
    
    $assumeResult = $assumeCall | ConvertFrom-Json
    
    $accessKeyId = $assumeResult.Credentials.AccessKeyId
    $secretAccessKey = $assumeResult.Credentials.SecretAccessKey
    $sessionToken = $assumeResult.Credentials.SessionToken
    
    # ===== Set environment variables so future aws requests are successfully authenticated & authorised =====
    $env:AWS_ACCESS_KEY_ID = $accessKeyId
    $env:AWS_SECRET_ACCESS_KEY = $secretAccessKey
    $env:AWS_SESSION_TOKEN = $sessionToken
}

# ===== Exports =====
Export-ModuleMember -Function 'Assume-Role'
