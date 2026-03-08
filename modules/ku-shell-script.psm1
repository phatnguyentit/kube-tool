Function Execute-Shell-Script() {
    $ScriptTemplate = Get-Template -TemplateType "shell-script"

    foreach ($DeploymentName in $ScriptTemplate.Keys) {

        $PodName = Get-ActivePod -Namespace $global:namespace -Deployment $DeploymentName

        if ($null -ne $PodName) {
            $Script = $ScriptTemplate[$DeploymentName]."shell-script"

            $Description = $ScriptTemplate[$DeploymentName]."description"
            if ($null -ne $Description -and $Description -ne '') {
                Write-Warning "We have some more information for this script`n__ Description: $Description"
            }

            $Confirm = Read-Host "Are you sure to run this script(y/n)?"

            if (IsAccept $Confirm) {
                if (UsingLinuxOs -PodName $PodName) {
                    Execute-Bash-Script -PodName $PodName -Script $Script
                }
                else {
                    Execute-Powershell-Script -PodName $PodName -Script $Script
                }
            }
            else {
                Write-Warning "Mission abort!"
            }
        }
    }
}