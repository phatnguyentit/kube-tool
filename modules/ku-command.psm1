# Return pod name if there is an active pod, else return $null
Function Get-ActivePod {
    [OutputType([string])]
    param(
        [parameter(Mandatory = $true)]
        [System.String] $Namespace,
        [parameter(Mandatory = $true)]
        [System.String] $Deployment
    ) 
  
    $LabelFiltering = "app.kubernetes.io/instance in ($global:buildset), app.kubernetes.io/name in ($Deployment)"
    $FieldSelector = "status.phase=Running"
    $Output = "{.items[*].metadata.name}"

    $podName = ku get pods --namespace=$Namespace -l $LabelFiltering --field-selector=$FieldSelector -o jsonpath=$Output

    if ($null -eq $podName) {
        Write-Alert "No active pod of '$Deployment' found in '$global:buildset'"
        Start-Sleep -Seconds 1
        return $null;
    }

    return $podName;
}


Function Get-ConfigMap-List {
    [OutputType([string[]])]
    param() 
    $LabelFiltering = "app.kubernetes.io/instance in ($global:buildset)"
    $Output = "{.items[*].metadata.name}"

    $configMapNames = ku get configmaps --namespace=$global:namespace -l $LabelFiltering -o jsonpath=$Output

    if ($null -eq $configMapNames -or '' -eq $configMapNames) {
        return $()
    }

    return $configMapNames.Split(' ');
}

Function Update-ConfigMap-By-Name {
    param(
        [parameter(Mandatory = $true)]
        [System.String] $ConfigMapName
    ) 

    ku edit configmap --namespace=$global:namespace $ConfigMapName
}

Function Update-Secret-By-Name {
    param(
        [parameter(Mandatory = $true)]
        [System.String] $SecretName
    ) 

    ku edit secret --namespace=$global:namespace $SecretName
}


Function Get-Secret-List {
    [OutputType([string[]])]
    param() 
    $LabelFiltering = "app.kubernetes.io/instance in ($global:buildset)"
    $Output = "{.items[*].metadata.name}"

    $secretNames = ku get secrets --namespace=$global:namespace -l $LabelFiltering -o jsonpath=$Output

    if ($null -eq $secretNames -or '' -eq $secretNames) {
        return $()
    }

    return $secretNames.Split(' ');
}

Function Update-Deployment {
    [OutputType([string[]])]
    param(
        [parameter(Mandatory = $true)]
        [System.String] $DeploymentName
    )
    $DeploymentFullName = "$Global:environment-$Global:tenant-$DeploymentName"
    ku edit -n $global:namespace deployment/$DeploymentFullName -o yaml --save-config
}

# Not ready to use
Function Get-Container-OS(
    [parameter(Mandatory = $true)]
    [System.String] $Namespace,
    [parameter(Mandatory = $true)]
    [System.String] $Deployment
) {
  
    $LabelFiltering = "app.kubernetes.io/instance in ($global:buildset), app.kubernetes.io/name in ($Deployment)"
    $FieldSelector = "status.phase=Running"
    $Output = "{.items[*].spec.nodeSelector.kubernetes\.io/os}"

    $osType = ku get pods --namespace=$Namespace -l $LabelFiltering --field-selector=$FieldSelector -o jsonpath=$Output

    if ($null -eq $podName) {
        Write-Alert "No active pod found in $global:buildset"
        return $null;
    }

    return $podName;
}

Function UploadFile([string]$LocalPodPath, [string]$TargetPath) {
    try {
        Write-Warning "Files are being uploaded into pod..."
        $PodName = $LocalPodPath | Split-Path -Leaf

        $IsLinuxOs = UsingLinuxOs -PodName $PodName

        if ($IsLinuxOs -eq $true) {
            $LocalPath = [System.IO.Path]::Combine($LocalPodPath, $TargetPath)
            $TargetPath = '.\'
        }
        else {
            $LocalPath = [System.IO.Path]::Combine($LocalPodPath, $TargetPath)
        }

        ku -n $Namespace cp $LocalPath "$($PodName):$($TargetPath)" --warnings-as-errors   
    }
    catch {
        Write-Warning "File '$LocalPath' was not uploaded sucessfully"
        Write-Error -Message $_
    }
}

Function DownloadFile([string]$PodName, [string]$RemotePath, [string]$LocalPath) {
    if (IsFilePath $RemotePath) {
        Write-Warning "Downloading file '$($RemotePath)'"
    }
    else {
        Write-Warning "Downloading directory '$($RemotePath)'"
    }

    ku -n $Namespace cp "$($PodName):$($RemotePath)" $LocalPath
}

Function Get-Deployment-Name {
    [OutputType([string[]])]
    param()
    $LabelFiltering = "app.kubernetes.io/instance in ($Global:buildset)"
    $Output = "{.items[*].metadata.labels.app\.kubernetes\.io/name}"

    $DeploymentNames = ku get deployment --namespace=$Global:namespace -l $LabelFiltering -o jsonpath=$Output

    return $DeploymentNames.Split(' ');
}

Function Get-Deployment-Status {
    [OutputType([string[]])]
    param(
        [parameter(Mandatory = $true)]
        [System.String] $Deployment
    )
    $LabelFiltering = "app.kubernetes.io/instance in ($Global:buildset), app.kubernetes.io/name in ($Deployment)"
    $JsonPath = "{range .items[*]}{.metadata.labels.app\.kubernetes\.io/name}{'#'}{.metadata.labels.app\.kubernetes\.io/version}{'#'}{.status.replicas}{'#'}{.status.updatedReplicas}{'#'}{.status.readyReplicas}{'#'}{'\n'}{end}"
    $Output = ku get deployment --namespace=$global:namespace -l $LabelFiltering -o jsonpath=$JsonPath

    return $Output;
}

# Obsolate
Function Get-Deployment-Version-With-Column() {
    $LabelFiltering = "app.kubernetes.io/instance in ($global:buildset)"
    $ColumnSelector = 'DeploymentName:.metadata.labels."app\.kubernetes\.io/name",Version:.metadata.labels."app\.kubernetes\.io/version"'
    $Output = ku get deployment --namespace=$global:namespace -l $LabelFiltering -o custom-columns=$ColumnSelector

    Write-Success "List of current deployments:"
    [int]$Index = 0
    foreach ($deployment in $Output) {
        if ($Index % 2 -eq 0) {
            Write-Host "# $deployment" -ForegroundColor Blue
        }
        else {
            Write-Host "# $deployment" -ForegroundColor Magenta
        }
        
        $Index++
    }
    
}

Function Get-Deployment-List() {
    $LabelFiltering = "app.kubernetes.io/instance in ($global:buildset)"
    $JsonPath = "{range .items[*]}{.metadata.labels.app\.kubernetes\.io/name}{'#'}{.metadata.labels.app\.kubernetes\.io/version}{'#'}{.status.replicas}{'#'}{.status.updatedReplicas}{'#'}{.status.readyReplicas}{'#'}{'\n'}{end}"
    $Output = ku get deployment --namespace=$global:namespace -l $LabelFiltering -o jsonpath=$JsonPath

    $DeploymentList = Get-ObjectsInOrder -Array $($Output | ToArray)

    return $DeploymentList
}

# Just a temporary approach, need to be improved!!!
Function UsingLinuxOs([string]$PodName) {
    $IsLinuxOs = $PodName.Contains("$global:tenant-infra")

    if ($IsLinuxOs -eq $true) {
        Write-Warning 'Technical warning: You are connecting to a linux container'
    }

    return $IsLinuxOs
}

Function Execute-Powershell-Script([string]$PodName, [string]$Script) {

    Write-Warning "Executing powershell script in '$PodName'`n...."
    ku exec --namespace=$global:namespace -i -t $PodName -- powershell -c "$Script"
}

Function Execute-Bash-Script([string]$PodName, [string]$Script) {

    Write-Warning "Executing powershell script in '$PodName'`n...."
    ku exec --namespace=$global:namespace -i -t $PodName -- sh -c "$Script"
}

Function Get-Log {
    [OutputType([string])]
    param([string]$PodName)
    $LogFileName = [System.IO.Path]::Combine('pod-log', "$($PodName).log")
    Write-Information "We're trieving pod log since last 8h"
    ku logs --namespace=$namespace $PodName --since=8h > $LogFileName    

    return $LogFileName
}

Function Restart-Deployment([string]$DeploymentName) {
    $DeploymentFullName = "$Global:environment-$Global:tenant-$DeploymentName"
    ku -n $global:namespace rollout restart deployment/$DeploymentFullName
    Write-Warning 'It can take 5 minutes to get the whole restart done'
}


