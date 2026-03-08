Import-Module -Force -DisableNameChecking "$PSScriptRoot\ku-template.psm1"

Function UpdateAppConfiguration() {
    $Configs = Get-Template -TemplateType "app-configuration"

    $Configs | ForEach-Object {
        foreach ($DeploymentName in $_.Keys) {
            Write-Warning "Loading configuration file in '$DeploymentName'"

            $PodName = Get-ActivePod -Namespace $Global:namespace -Deployment $DeploymentName

            if ($null -ne $PodName) {
                foreach ($config in $_[$DeploymentName]) {
                    Get-Config -DeploymentName $DeploymentName -PodName $PodName -RemoteFile $config          
                }
            }

        }
    }
}

Function Get-Config {
    param
    (
        [parameter(Mandatory = $true)]
        [System.String] $DeploymentName,

        [parameter(Mandatory = $true)]
        [System.String] $PodName,

        [parameter(Mandatory = $true)]
        [System.String] $RemoteFile
    )
    process {
        if ($null -ne $PodName) {
            $LocalPodPath = [System.IO.Path]::Combine('ku-context', $global:namespace, $DeploymentName, $PodName)
            $LocalFile = [System.IO.Path]::Combine($LocalPodPath, $RemoteFile);

            $FileExtension = [System.IO.Path]::GetExtension($LocalFile)
            if ($FileExtension -ne '.config' -and $FileExtension -ne '.json') {
                Write-Warning "File with extension '$FileExtension' is not supported."
                return;
            }
            
            try {
                DownloadFile -PodName $PodName -RemotePath $RemoteFile -LocalPath $LocalFile
                
                $Process = Start-Process -FilePath $LocalFile

                $save = Read-Host -Prompt "Do you want to upload this file? (y/n)"

                if ([bool](IsAccept $save) -eq $true) {
                    UploadFile -LocalPodPath $LocalPodPath -TargetPath $RemoteFile
                }
                
                if ($null -ne $Process) {
                    Stop-Process -InputObject $Process
                }
                
                Remove-Pod-Folder -PodName $PodName
            }
            catch {
                Write-Warning "Remote file $($RemoteFile) was not downloaded suceesfully"
                Write-Error -Message $_
            }
        }
        
    }
}