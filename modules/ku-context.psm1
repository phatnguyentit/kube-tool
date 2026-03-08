
# Return pod location if there is an active pod, else return $false
Function New-Pod-Folder (
    [parameter(Mandatory = $true)]
    [System.String] $Namespace,
    [parameter(Mandatory = $true)]
    [System.String] $Deployment,
    [parameter(Mandatory = $true)]
    [System.String] $PodName
) {
    $ContextFolder = [System.IO.Path]::Combine($PWD, 'ku-context')

    if ($null -ne $PodName) {
        $Path = [System.IO.Path]::Combine($ContextFolder, $Namespace, $Deployment, $PodName)

        Remove-Deployment-Folder -DeploymentPath ([System.IO.Path]::Combine($ContextFolder, $Namespace, $Deployment, '*'))
       
        New-Item -ItemType Directory -Path $Path
  
        return $Path;
    }
      
    return $null;
}

Function Remove-Deployment-Folder([string]$DeploymentPath) {
    if (Test-Path -PathType Container $DeploymentPath) {
        Remove-Item -Path $DeploymentPath -Recurse
    }
}


Function CopyToContext(
    [parameter(Mandatory = $true)]
    [System.String] $ActualPath,
    [parameter(Mandatory = $true)]
    [System.String] $Namespace,
    [parameter(Mandatory = $true)]
    [System.String] $Deployment,
    [parameter(Mandatory = $true)]
    [System.String] $PodFolder
) {
    $FullPodPath = [System.IO.Path]::Combine($PWD, 'ku-context', $Namespace, $Deployment, $PodFolder)
    If (!(Test-Path -PathType container $FullPodPath)) {
        New-Item -ItemType Directory -Path $FullPodPath
    }
    Copy-Item -Path $ActualPath -Recurse -Destination $FullPodPath -Force
}

Function Clear-ContextData() {
    Remove-Item -Path "$PWD\ku-context\*" -Recurse
}

Function Remove-Pod-Folder([string]$PodName) {
    $PodPath = Get-ChildItem -Path "$PWD\ku-context\" -Recurse -Filter $PodName
    Write-Warning "Removing local pod folder ..."

    if (Test-Path -Path $PodPath.FullName) {
        try {
            Remove-Item -Path $PodPath.FullName -Recurse -Force
            Start-Sleep -Seconds 1
        }
        catch {
            Write-Alert "Pod folder '$PodName' is NOT removed after uploading yet, please remove it manually"
            return
        }
    }

}