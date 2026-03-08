Import-Module -Force -DisableNameChecking "$PSScriptRoot\ku-template.psm1"

Function DownloadByTemplate() {
    $DownloadTemplate = Get-Template -TemplateType "download"

    foreach ($DeploymentName in $DownloadTemplate.Keys) {
        $PodName = Get-ActivePod -Namespace $global:namespace -Deployment $DeploymentName
        
        if ($null -ne $PodName) {
            New-Pod-Folder -Namespace $global:namespace -Deployment $deploymentName -PodName $PodName

            $LocalPodPath = [System.IO.Path]::Combine('ku-context', $global:namespace, $DeploymentName, $PodName)

            $RemoteItemCollection = $DownloadTemplate[$DeploymentName]
            [Int16]$SuccessCount = 0

            foreach ($RemoteItem in $RemoteItemCollection) {
                if (([string]$RemoteItem).EndsWith('*')) {
                    Write-Alert "We do not support to download all items in a folder using symbol '*'"
                    return
                }

                $LocalPath = $([System.IO.Path]::Combine($LocalPodPath, $RemoteItem)).TrimEnd('\').TrimEnd('/')
                
                DownloadFile -PodName $PodName -RemotePath $RemoteItem -LocalPath $LocalPath

                if (Test-Path -Path $LocalPath) {
                    $SuccessCount++
                    Write-Success "'$LocalPath' is saved"
                }
                else {
                    Write-Alert "'$LocalPath' is NOT saved"
                }
            }

            if ($RemoteItemCollection.Count -eq $SuccessCount) {
                Write-Warning "Opening local pod folder, your downloaded files are there"
                Start-Sleep -Seconds 1
                Start-Process $LocalPodPath
            }
            
        }
    }
}