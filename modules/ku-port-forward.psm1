Function PortForward-By-Template() {
    $Options = @('Get current port forwarding', 'Start port forwarding')

    $Option = Get-Option-From-List -Options $Options -Prompt 'What I can help you?'

    if ($Option.Number -eq 1) {
        if ($null -ne $Global:PortForwardConfig) {
            # Check current forwarding
            Write-Output $Global:PortForwardConfig | ft
        }
        else {
            Write-Warning 'No active port forwaring'
        }
    }
    else {
        
        $ScriptTemplate = Get-Template -TemplateType "force-port-forward"

        $PodName = Get-ActivePod -Namespace $global:namespace -Deployment $ScriptTemplate.deployment

        if ($null -ne $PodName) {
            [int]$AvailablePort = 0
            [int]$LocalPort = $ScriptTemplate.'local-port'
            [int]$RemotePort = $ScriptTemplate.'remote-port'

            if ($null -eq $Global:PortForwardConfig) {
                $AvailablePort = Get-Available-Port -Port $LocalPort
            }
            else {
                if ($Global:PortForwardConfig.LocalPort -eq $LocalPort -and $global:PortForwardConfig.PodName -eq $PodName) {
                    Write-Warning "You're already using port forwarding: 127.0.0.1:$LocalPort --> $($PodName):$RemotePort"
                    return
                }
                else {
                    $AvailablePort = Get-Available-Port -Port $LocalPort
                }
            }

            Write-Warning "Verifying the port forwarding..."

            if ($AvailablePort -ne 0) {
                $JobScript = {
                    param($p1, $p2, $p3, $p4)
                    kubectl -n $p1 port-forward "$p2" "$($p3):$p4"
                }
    
                $Job = Start-Job -ScriptBlock $JobScript -ArgumentList @($global:namespace, $PodName, $AvailablePort, $RemotePort)

                [PortForwardConfig]$PortForwardConfig = $null
                [int]$Attemps = 1
                [int]$MaxAttempts = 10

                do {
                    if ($Attemps -gt $MaxAttempts) {
                        break
                    }
                    if ((Is-Available -Port $AvailablePort) -eq $false) {
                        Write-Success "Port forwarding succeeded: 127.0.0.1:$($AvailablePort) --> $($PodName):$RemotePort"
                
                        # Finally
                        $PortForwardConfig = [PortForwardConfig]::new();
                        $PortForwardConfig.DeploymentName = $ScriptTemplate.deployment
                        $PortForwardConfig.PodName = $PodName 
                        $PortForwardConfig.LocalPort = $AvailablePort
                        $PortForwardConfig.RemotePort = $RemotePort
                        break;
                    }
                    else {
                        Write-Warning "Attemps: $Attemps/$MaxAttempts ..."
                        $Attemps++
                    }
                } until ($null -ne $PortForwardConfig)

                if ($null -eq $PortForwardConfig) {
                    Receive-Job -Job $Job -Wait
                }
                else {
                    $global:PortForwardConfig = $PortForwardConfig;
                }
            }
            else {
                Write-Alert "Something wrong, please contact administrator"
            }
        }

    }

}

Function Get-Available-Port {
    [OutputType([int])]
    param([int]$Port)

    [Int16]$Attempts = 0
    [Int16]$MaxAttempts = 5

    while ($(Is-Available -Port $Port) -eq $false -and $Attempts -lt $MaxAttempts) {
        Write-Warning "Local port $Port is already in use. Trying with new port $($Port++)"
        $Attempts++;
        Start-Sleep -Seconds 1
    }

    if ($Attempts -ge $MaxAttempts) {
        Write-Alert "We've tried $MaxAttempts times to find a port but no hope!"
        return 0;
    }

    Write-Success "Local port $Port is available. We're gonna use it"
    return $Port;
}

class PortForwardConfig {
    [string]$DeploymentName
    [string]$PodName
    [int]$LocalPort
    [int]$RemotePort
}

Function Is-Available {
    [OutputType([bool])]
    param([Int32]$Port)
    $Result = (Test-Port -ComputerName '127.0.0.1' -Port $Port)
    return $Result -eq $false
}