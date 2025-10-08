# performance-app-backend DEV stop (PowerShell)
$ErrorActionPreference = "SilentlyContinue"
Set-Location -LiteralPath $PSScriptRoot
$runDir = Join-Path $PSScriptRoot ".run"
$pidFile = Join-Path $runDir "bootrun.pid"

if(Test-Path $pidFile){
  try {
    $pid = Get-Content $pidFile | Select-Object -First 1
    if($pid){ Stop-Process -Id $pid -Force }
  } catch {}
  Remove-Item $pidFile -ErrorAction SilentlyContinue
}

.\gradlew.bat --stop | Out-Null
docker compose down -v
Write-Host "[DEV] stopped."
