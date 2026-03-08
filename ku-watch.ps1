Write-Warning "I'm watching your local change...."

$FilePath = "$PWD\ku-context\*"

if (!(Test-Path -Path $FilePath)) {
    Write-Error -Message "File $FilePath does not exist!"
}


$AttributeFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite

$FileDirectory = Split-Path -Path $FilePath -Parent

$KeepWatching = $true
$Save = $false

try {
    $eventSubcriber = New-Object -TypeName System.IO.FileSystemWatcher -Property @{
        Path                  = $FileDirectory
        Filter                = '*.*'
        IncludeSubdirectories = $true
        NotifyFilter          = $AttributeFilter
    }

    $eventAction = {
        $EventArguments = $event.SourceEventArgs
        $FullPath = $EventArguments.FullPath                   
        $ChangeType = $EventArguments.ChangeType

        $TimeGenerated = $event.TimeGenerated

        $warningText = "# {0}: {1} was {2}" -f $TimeGenerated, $FullPath, $ChangeType
        Write-Host ""
        
        switch ($ChangeType) {
            'Changed' {
                Write-Host $warningText -ForegroundColor Yellow
                $Save = $true
                $KeepWatching = $false;
                BREAK;
            }
            'Deleted' {
                Write-Host $warningText
                # Write-Host "Nothing to be saved into the pod"
                $KeepWatching = $false;
                BREAK;
            }
            'Renamed' { 
                Write-Host $warningText -ForegroundColor Yellow
                # Write-Host "A renamed file won't be saved into the pod"
                $KeepWatching = $false;
                BREAK;
            }     
            'Created' {
                Write-Host $warningText
                Copy-Item -Path $FullPath -Destination ([System.IO.Path]::Combine($PWD, 'ku-context-log'))
                $Save = $true
                $KeepWatching = $false;
                BREAK;
            }   
            default {
                Write-Host $warningText -ForegroundColor
                $KeepWatching = $false;
                BREAK;
            }
        }
    }

    $eventHandlers = . {
        Register-ObjectEvent -InputObject $eventSubcriber -EventName Changed -Action $eventAction 
        Register-ObjectEvent -InputObject $eventSubcriber -EventName Deleted -Action $eventAction 
        Register-ObjectEvent -InputObject $eventSubcriber -EventName Renamed -Action $eventAction 
        Register-ObjectEvent -InputObject $eventSubcriber -EventName Created -Action $eventAction 
    }

    $eventSubcriber.EnableRaisingEvents = $true

    do {
        Wait-Event -Timeout 2
        Write-Host "*" -NoNewline -ForegroundColor Yellow

    } while ($KeepWatching)

    return $Save;
}
finally {
    $eventSubcriber.EnableRaisingEvents = $false

    $eventHandlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
    }

    $eventHandlers | Remove-Job
    $eventSubcriber.Dispose()

    Write-Warning "File watcher has stopped!"
}  