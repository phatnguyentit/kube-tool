Function IsAccept
(
  [parameter(Mandatory = $true)]
  $Confirm
) {
  return $Confirm -eq 'y' -or $Confirm -eq 'Y';
}


Function ToArray {
  begin {
    $item = @();
  }
  process {
    $item += $_;
  }
  end {
    return , $item;
  }
}

Function Get-ObjectsInOrder() {
  param(
    [Array] $Array
  )
  $dict = New-Object System.Collections.Generic.Dictionary"[Int,Object]"
  
  foreach ($item in $Array) {
    $dict.Add(($Array.IndexOf($item) + 1), $item);
  }
  return $dict;
}

Function Write-Objects-InOrder([System.Object[]]$Array) {
  $ObjectsInOrder = Get-ObjectsInOrder -Array $Array

  $ObjectsInOrder.Keys | ForEach-Object {
    if ($_ % 2 -eq 0) {
      Write-Host " #$_. $($ObjectsInOrder[$_])"
    }
    else {
      Write-Host " #$_. $($ObjectsInOrder[$_])"
    }
  }

  return $ObjectsInOrder;
  
}

Function Get-Option-From-List {
  [OutputType([PSCustomObject])]
  param(
    [string[]]$Options,
    [string]$Prompt,
    [Parameter(Mandatory = $false)][string]$Default
  )
  
  $OptionsInOrder = Write-Objects-InOrder -Array $Options
  $Option = 0;

  do {
    $Option = Read-Host -Prompt $Prompt

    if ($null -ne $Default -and $Option -eq '' -or $Option -eq $Default) {
      Write-Warning "Default option '$Default' is used"
      return @{Number = 1000; Value = $Default }
    }

    if ($Option -eq 'q' -or $Option -lt 1) {
      return $null
    }

  } until (IsNumber $Option -and [int]$Option -lt $OptionsInOrder.Keys.Length)

  Write-Information "`nYou chose '$($OptionsInOrder[$Option])'"
  return @{Number = $Option; Value = $($OptionsInOrder[$Option]) }
}

Function Get-Option {
  param(
    [int]$MaxOptions,
    [string]$Prompt,
    [Parameter(Mandatory = $false)][string]$Default
  )
  
  do {
    $Option = Read-Host -Prompt $Prompt

    if ($null -ne $Default -and $Option -eq '' -or $Option -eq $Default) {
      Write-Warning "Default option '$Default' is chosen"
      return @{Number = 100; Value = $Default }
    }

    if ($Option -eq 'q' -or $Option -lt 1) {
      return $null
    }

  } until (IsNumber $Option -and [int]$Option -lt $($MaxOptions + 1))

  return $Option
}

Function IsNumber([string]$Text) {
  return $Text -match "^\d+$";  
}

Function Write-Alert([string]$Message) {
  Write-Host "FAILURE: $Message" -ForegroundColor Red
  Start-Sleep -Seconds 1
}

Function Write-Success([string]$Message) {
  Write-Host "NICE! $Message" -ForegroundColor Green
  Start-Sleep -Seconds 1
}

Function Write-Information([string]$Message) {
  Write-Host "INFORMATION! $Message" -ForegroundColor Black -BackgroundColor White
}

Function Write-Tip([string]$Message) {
  Write-Host "Tips! $Message" -ForegroundColor Black -BackgroundColor Blue
}

Function IsFilePath {
  [OutputType([bool])]
  param([string]$Path)

  if ($Path -eq '' -or $null -eq $Path) {
    return $false
  }

  $Items = $Path.Split('\')

  return $Items[$Items.Length - 1].Contains('.')
}

Function Add-EndPath {
  [OutputType([string])]
  param (
    [string]$Path
  )
  
  if (!$Path.EndsWith('\')) {
    return "$Path\"
  }

  return $Path

}

Function Invoke-With-Callback {
    param(
        [Parameter(Mandatory)]
        [ScriptBlock]$Callback,
        [Parameter(Mandatory = $false)]
        $Argument
    )

    if ($null -ne $Argument) {
        & $Callback $Argument
    } else {
        & $Callback
    }
}