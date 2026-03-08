Import-Module -Force -DisableNameChecking "$PSScriptRoot\ku-template.psm1"

Function UploadByTemplate() {
    $uploadTemplate = Get-Template -TemplateType "upload"

    foreach ($DeploymentObject in $uploadTemplate.remote) {

        foreach ($deploymentName in $DeploymentObject.Keys) {
            $PodName = Get-ActivePod -Namespace $global:namespace -Deployment $deploymentName
            $TargetPath = $DeploymentObject[$deploymentName]

            if ($null -ne $PodName) {
                $PodFolder = New-Pod-Folder -Namespace $global:namespace -Deployment $deploymentName -PodName $PodName
    
                if ($null -ne $PodFolder) {
                    foreach ($LocalPath in $uploadTemplate.local) {
                        if (!(Test-Path -Path $LocalPath)) {
                            Write-Alert "Oh no mission incomplete. We found out the following path is not reallll:`n $LocalPath"
                            return
                        }
                        
                        $PreparedPodPath = [System.IO.Path]::Combine($PodName, $TargetPath)
                        CopyToContext -ActualPath $LocalPath -Namespace $global:namespace -Deployment $deploymentName -PodFolder $PreparedPodPath
                    }

                    $LocalPodPath = [System.IO.Path]::Combine('ku-context', $global:namespace, $deploymentName, $PodName)

                    UploadFile -LocalPodPath $LocalPodPath -TargetPath $TargetPath
                }
                
                Remove-Pod-Folder -PodName $PodName
            }
        }
        
    }
}