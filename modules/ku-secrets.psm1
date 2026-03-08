Function Update-Secret() {
    $Secrets = Get-Secret-List

    if ($Secrets.Length -gt 0) {
        do {
            $ChosenSecret = Get-Option-From-List -Options $Secrets -Prompt "Which secret do you want to update?"
            if ($null -ne $ChosenSecret) {
                $SecretName = $ChosenSecret.Value
                Update-Secret-By-Name $SecretName
            }
        } until ($null -eq $ChosenSecret)
    }
    else {
        Write-Warning "There is no secret found"
    }
}