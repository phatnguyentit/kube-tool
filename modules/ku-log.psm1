Function Get-Log-By-Deployment([string]$DeploymentName) {
    $PodName = Get-ActivePod -Namespace $Global:namespace -Deployment $DeploymentName

    if ($null -ne $PodName) {
       
        $LogFilePath = Get-Log -PodName $PodName

        if (Test-Path -Path $LogFilePath) {
            Start-Process $LogFilePath
        }
    }
}