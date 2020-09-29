# ===== Resetting AWS roles =====
function Reset-Role() {
    $env:AWS_ACCESS_KEY_ID = $null
    $env:AWS_SECRET_ACCESS_KEY = $null
    $env:AWS_SESSION_TOKEN = $null
}

# ===== Exports =====
Export-ModuleMember -Function 'Reset-Role'
