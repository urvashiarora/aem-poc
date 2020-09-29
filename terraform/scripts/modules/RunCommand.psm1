# ===== Generic Run-command for handling common AWS issues =====

function Run-Command {
param(
  [parameter(Mandatory = $true)]
  [String]$Command,

  [parameter(Mandatory = $false)]
  [int]$Retries = 3,

  [parameter(Mandatory = $false)]
  [switch]$IgnoreFinalError = $false
)

    # ===== RUN THE COMMAND AND RETRY IF THE AWS CREDENTIALS ERROR IS PRESENT
    $AwsCredsErrorRetries = $Retries
    $Tries = 1

    DO {
        $LastCommandErrors = $null
        Write-Host "running this: $Command, try #$Tries of $AwsCredsErrorRetries"
        Invoke-Expression "& $Command 2>''" -OutVariable LastCommandOutput -ErrorVariable LastCommandErrors
        $Tries++
    } while ((($LastCommandErrors -join '') -match "Unable to locate credentials") -and ($Tries -le $AwsCredsErrorRetries))

    # ===== IGNORING 'WORKSPACE ALREADY EXISTS' ERROR AS THIS IS SOMETIMES EXPECTED
    if (($LastCommandErrors -join '') -match "Workspace `"$Env:WORKSPACE`" already exists") {
        return
    }

    Write-Host "LastCommandErrors = $LastCommandErrors"
    Write-Host "Last Powershell Command = $?"
    # ===== ONCE THE ABOVE IS FINISHED, THE COMMAND EITHER PASSED OR CONTAINED A PERSISTENT ERROR, OR POWERSHELL FAILED
    if (($LastCommandErrors -or !$? ) -and (-not $IgnoreFinalError)) {
        Write-Host "Something went wrong, see the output above"
        exit 1
    } else {
        return
    }
 }

 # ===== Exports =====
Export-ModuleMember -Function 'Run-Command'
