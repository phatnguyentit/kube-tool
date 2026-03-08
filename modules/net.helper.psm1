Function Test-Port {
  [OutputType([bool])]
  param (
    [string]$ComputerName,
    [int]$Port
  )
 
  # Create a Net.Sockets.TcpClient object to use for
  # checking for open TCP ports.
  $Socket = New-Object Net.Sockets.TcpClient
        
  # Suppress error messages
  $ErrorActionPreference = 'SilentlyContinue'
        
  # Try to connect
  $Socket.Connect($ComputerName, $Port)
        
  # Make error messages visible again
  $ErrorActionPreference = 'Continue'
        
  # Determine if we are connected.
  if ($Socket.Connected) {
    $Socket.Close()
    return $true
  }
  else {
    return $false
  }
        
  # Apparently resetting the variable between iterations is necessary.
  $Socket.Dispose()
  $Socket = $null
}