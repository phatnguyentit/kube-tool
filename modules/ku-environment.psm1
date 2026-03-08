function CheckConfiguration() {
  
  $ValidationResult = PrecheckConfiguration
  if ($false -eq $ValidationResult) {
    Start-Sleep -Seconds 2
    exit;
  }

  do {
    $global:environment = Set-Environment
  } until ($null -ne $global:environment)

  Write-Information "Environment '$global:environment' is set!"

  do {
    $global:tenant = Set-tenant
  } until ($null -ne $global:tenant)

  Write-Information "tenant '$global:tenant' is set!"

  $ValidationResult = PostcheckConfiguration
  if ($false -eq $ValidationResult) {
    Start-Sleep -Seconds 2
    exit;
  }
}


Function PrecheckConfiguration () {
  
  $KuConfig = Get-AppConfig;
  $RequiredKubeContext = $KuConfig."kube-context";

  if ($(kubectl config current-context) -eq $RequiredKubeContext) {
    $global:namespace = $KuConfig."namespace";
	  
    Write-Information "We're using kube context '$($KuConfig."kube-context")'`nNamespace '$global:namespace'"
    Set-Alias -Name ku -Value kubectl -Scope 'Global'
    return $true;
  }
  else {
    Write-Alert "kube context '$RequiredKubeContext' is not set"
    return $false;
  }
}

Function PostcheckConfiguration () {
  
  $KuConfig = Get-AppConfig;
  $HelmReleases = $KuConfig."helm-release-set"

  if ($null -eq $HelmReleases -or $HelmReleases -eq '' -or $HelmReleases.Length -eq 0) {
    Write-Warning "There is no configuration for 'helm-release-set'"
    return $false;
  }
  else {
    $ReleaseList = New-Object Collections.Generic.List[String]

    foreach ($release in $HelmReleases) {
      $release = $release.Replace('$Environment', $global:environment).Replace('$tenant', $global:tenant);

      if ($release.Contains('$') -or $null -eq $release -or $release -eq '') {
        Write-Warning "Environment or tenant name is not supported."
        return $false;
      }

      $ReleaseList.Add($release)
    }

  }
  
  $global:buildset = ($ReleaseList -join ',')

  return $true;
}
  
Function Set-Environment () {
  Write-Host "Environments:"
  
  $EnvironmentInOrder = Write-Objects-InOrder -Array ($(Get-AppConfig))."environment-set"
  
  $Env = Read-Host -Prompt "Please enter a number or type your own environment name"
  
  if (IsNumber $Env) {
    $EnvIndex = [Int]$Env;
  
    if ($EnvIndex -gt $EnvironmentInOrder.Count -or $EnvIndex -lt 1) {
      Write-Warning "We only have $($EnvironmentInOrder.Count) environments"
      return $null;
    }
    else {
      return $EnvironmentInOrder[$EnvIndex]
    }
  }
  if ($Env.Length -lt 1) {
    Write-Warning "That's not an environment name"
    return $null;
  }
  else {
    return $Env;
  }
}

Function Set-tenant () {  
  Write-Host "Customers:"
  $Option = Get-Option-From-List -Options $($(Get-AppConfig)."tenant-set") -Prompt 'Which tenant do you want?' -Default 'volksbank'

  return $Option.Value;

}

  
Function Get-AppConfig() {
  $KuConfigPath = "$PWD\appconfig.yaml";
  return ConvertFrom-Yaml (Get-Content -Path $KuConfigPath -Raw)
}

Function Write-Environment-Information() {
  Write-Host "You're working with environment '$Global:environment-$Global:tenant'" -ForegroundColor White -BackgroundColor Green
}
  