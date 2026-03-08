Function Get-Deployment-Walkthrough() {
    Clear-Host

    do {
        $DeploymentInOrders = Get-Deployment-List

        Show-Deployment-List -DeploymentInOrders $DeploymentInOrders
        Write-Tip "Enter 'r' to refresh the list, 'q' to quit"
        
        $Refresh = Read-Host -Prompt "Do you want to refresh after some* seconds(number*/n)"

        if($Refresh -ne $null -and (IsNumber $Refresh)){
            
        }
        else{
        
        }

        $DeploymentNumber = Get-Option -MaxOptions $DeploymentInOrders.Length -Prompt 'Which deployment you want to walk through?' -Default 'r'
        
        

        while ($null -ne $DeploymentNumber -and $(IsNumber $DeploymentNumber) -and $DeploymentNumber.Value -ne 'r') {
            $DeploymentName = $DeploymentInOrders[$DeploymentNumber].Split('#')[0]
            Write-Information "`nYou chose '$DeploymentName'"

            if ($null -eq $Action) {
                $DeploymentMenu = @('Get log', 'Edit deployment manifest', 'Restart')
                $Action = Get-Option-From-List -Options $DeploymentMenu -Prompt "What do you want to do with '$DeploymentName'?"
            }

            if ($Action.Number -eq 1) {
                Get-Log-By-Deployment -DeploymentName $DeploymentName
            }

            if ($Action.Number -eq 2) {
                Update-Deployment -DeploymentName $DeploymentName
            }

            if ($Action.Number -eq 3) {
                Restart-Deployment -DeploymentName $DeploymentName
                # $observe = Read-Host -Prompt "Do you want to observe the deployment until it's ready(y/n)?"
                # if (IsAccept $observe) {
                #     while ($true) {
                #         $DeploymentStatus = Get-Deployment-Status -Deployment $Name
                #         start-process powershell -ArgumentList '-noexit -command 'Write-Line''
                #         Start-Sleep -Seconds 5
                #     }
                # }
                # return
            }
            $DeploymentNumber = Read-Host -Prompt "Do the same action for another deployment (just enter a number or 'q' to back)"
        }

        Clear-Host
    } while ($null -ne $DeploymentNumber.Number -and $DeploymentNumber.Value -eq 'r')

    
}

Function Show-Deployment-List([parameter()]$DeploymentInOrders) {
    $DeploymentInOrders.Keys | Select-Object @{n = '#'; e = { " #$_." } },
    @{n = 'Name'; e = { $DeploymentInOrders[$_].Split('#')[0] } },
    @{n = 'Version'; e = { $DeploymentInOrders[$_].Split('#')[1] } },
    @{n = 'Total replicas'; e = { $DeploymentInOrders[$_].Split('#')[2] } },
    @{n = 'Ready replicas'; e = { $DeploymentInOrders[$_].Split('#')[4] } },
    @{n = 'Status'; e = {
            $totalReplicas = $DeploymentInOrders[$_].Split('#')[2]
            $updatedReplicas = $DeploymentInOrders[$_].Split('#')[3]
            $readyReplicas = $DeploymentInOrders[$_].Split('#')[4]
            if ($readyReplicas -eq $totalReplicas -and $totalReplicas -eq $updatedReplicas) {
                return 'READY'
            }
            else {
                if ($readyReplicas -lt $totalReplicas -and $totalReplicas -eq $updatedReplicas) {
                    return '... WAITING FOR NEW REPLICAS'
                }
                if ($readyReplicas -lt $totalReplicas -and $totalReplicas -gt $updatedReplicas) {
                    return '... RESTARTING'
                }
                else {
                    return ''
                }
            }
        } 
    } | Format-Table
}