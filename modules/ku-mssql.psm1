Function Invoke-SqlScript-By-Template() {
    $ScriptTemplate = Get-Template -TemplateType "sql-script"

    if ($null -ne $ScriptTemplate) {

        $DatabaseName = $ScriptTemplate.database;

        if ($null -ne $global:PortForwardConfig) {
            $Server = "127.0.0.1,$($global:PortForwardConfig.LocalPort)"
            $SqlFilePath = [System.IO.Path]::Combine('ku-template', 'sql-script', 'scripts', $ScriptTemplate.scriptfile)
    
            if (!(Test-Path -Path $SqlFilePath)) {
                Write-Alert "Oh no, we could not find out the script file"
                return;
            }
    
            if ((Get-Item $SqlFilePath) -is [System.IO.DirectoryInfo]) {
                Write-Alert "We do not support execure script(s) inside a directory for now"
                return;
            }
            
            if ($null -ne $ScriptTemplate.description -and $ScriptTemplate.description -ne '') {
                Write-Warning "We have some more information for this script`n__ Description: $($ScriptTemplate.description)"
            }

            $Confirm = Read-Host "Are you sure to run this script(y/n)?"

            if (IsAccept $Confirm) {
                Invoke-Script -Server $Server -DatabaseName $DatabaseName -SqlFilePath $SqlFilePath -ExportResult $ScriptTemplate.'json-output'
            }
            else {
                Write-Warning "Mission abort!"
            }
    
            
        }
        else {
            Write-Alert "No active port found for database server. Please start new port forwarding"
        }
    }

}

Function Invoke-Script
(
    [string]$Server,
    [string]$DatabaseName,
    [string]$SqlFilePath,
    [bool]$ExportResult
) {
    try {
        $Query = Get-Content $SqlFilePath -Raw
        $Query = $Query.Replace('[DatabaseName]', $DatabaseName)

        $ExecuteResult = Invoke-Sqlcmd -ConnectionString "Data Source=$Server; User Id=sa; Password =23wesdXC;TrustServerCertificate=true" -QueryTimeout 900 -Query $Query -ErrorAction Stop -verbose

        if ($ExportResult -eq $true) {
            $SqlName = $SqlFilePath | Split-Path -Leaf
            $ExportPath = [System.IO.Path]::Combine('sql-result', "$($SqlName).result.json")
            $ExecuteResult | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | ConvertTo-Json | Out-File $ExportPath
            Start-Process -FilePath $ExportPath
        }
    }
    catch {
        Write-Alert $_
    }
}


