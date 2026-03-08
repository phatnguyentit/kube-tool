Function Update-ConfigMap() {
    $ConfigMaps = Get-ConfigMap-List

    if ($ConfigMaps.Length -gt 0) {
        do {
            $ChosenConfig = Get-Option-From-List -Options $ConfigMaps -Prompt "Which config do you want to update (or enter 'q' to quit)?"
            if ($null -ne $ChosenConfig) {
                $ConfigName = $ChosenConfig.Value
                Update-ConfigMap-By-Name $ConfigName
            }
        } until ($null -eq $ChosenConfig)
    }
    else {
        Write-Warning "There is no configmaps found"
    }
}