Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\common.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\net.helper.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-command.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-environment.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-app-configuration.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-upload.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-download.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-context.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-mssql.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-deployment-walkthrough.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-port-forward.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-configmaps.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-shell-script.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-log.psm1"
Import-Module -Force -DisableNameChecking "$PSScriptRoot\modules\ku-procedure.psm1"

if ($null -eq (Get-InstalledModule -Name powershell-yaml)) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Install-Module -Name powershell-yaml -Force
    }
    else {
        Write-Warning "Please run me as Administrator at first to install some essential modules"
        Start-Sleep -Seconds 2
        exit;
    }
}

Write-Warning "Checking configuration"
(CheckConfiguration)
Clear-Host

$host.UI.RawUI.WindowTitle = "$global:environment-$global:tenant"

$Options = @(
    'Update configuration',
    'Upload somethings',
    'Download somethings',
    'Port forwarding',
    'Execute sql script',
    'Walkthrough deployments',
    'Update ConfigMaps',
    'Execute shell script',
    'Execute procedure')

Do {
    Start-Sleep -Seconds 1
    Write-Environment-Information
    Write-Host '---------------------------'
    Write-Tip "Enter 'q' to go back, 'c' to clean up local data"

    $Option = Get-Option-From-List -Options $Options -Prompt 'What I can help you?' -Default 'c'

    if ($Option.Value -eq 'c') {
        Write-Warning "Clearing 'ku-context'"
        Clear-ContextData
    }
    else {
        Switch ($Option.Number) {
            1 {
                UpdateAppConfiguration
                Break
            }
    
            2 {
                UploadByTemplate
                Break
            }
    
            3 {
                DownloadByTemplate
                Break
            }
    
            4 {
                PortForward-By-Template
            }
    
            5 {
                Invoke-SqlScript-By-Template
                Break
            }
    
            6 {
                Get-Deployment-Walkthrough
                Break
            }
    
            7 {
                Update-ConfigMap
                Break
            }
    
            8 {
                Execute-Shell-Script
                Break
            }

            9 {
                Execute-Procedure
                Break
            }
            
            $null {
                Write-Warning "Goodbye. Have a nice day!"
                Start-Sleep -Seconds 1
                exit;
            }
    
            Default {
                Write-Alert "Hmm. What do you mean?"
                break;
            }
        }
    }
}While ($true)