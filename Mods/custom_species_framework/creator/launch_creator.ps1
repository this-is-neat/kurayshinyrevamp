$ErrorActionPreference = "Stop"

$script:CreatorRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ServerScript = Join-Path $script:CreatorRoot "creator_server.ps1"
$script:PreferredPort = 39077

function Stop-StaleCreatorServers {
  $self = $PID
  Get-CimInstance Win32_Process |
    Where-Object {
      $_.ProcessId -ne $self -and
      $_.Name -eq "powershell.exe" -and
      $_.CommandLine -like "*creator_server.ps1*"
    } |
    ForEach-Object {
      try {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop
      } catch {
      }
    }
}

Stop-StaleCreatorServers
Start-Sleep -Milliseconds 300

$previousPort = $env:CSF_CREATOR_PORT
try {
  $env:CSF_CREATOR_PORT = [string]$script:PreferredPort
  & $script:ServerScript
} finally {
  $env:CSF_CREATOR_PORT = $previousPort
}
