#Requires -Version 5.1
param(
  [int]$Port = 8082
)

$ErrorActionPreference = "SilentlyContinue"
$LOG = "[PROD]"

Set-Location -LiteralPath $PSScriptRoot
Write-Host "$LOG Stopping..."

function TryStop-ProcId([int]$procId, [string]$label = ""){
  if($procId -le 0){ return }
  $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
  if($p){
    $name = $p.ProcessName
    Write-Host "$LOG Kill PID $procId ($name)$label"
    & taskkill /PID $procId /T /F *> $null
    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
  }
}

# PID fájlokból leállítás
$runDir   = Join-Path $PSScriptRoot ".run"
$pidFiles = @(
  Join-Path $runDir "bootrun.prod.pid",  # prod-start által javasolt név
  Join-Path $runDir "bootrun.pid"        # ha mégis ezt használod
) | Where-Object { Test-Path $_ }

foreach($f in $pidFiles){
  $pidText = (Get-Content $f -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
  [int]$procId = 0
  if([int]::TryParse($pidText, [ref]$procId)){
    TryStop-ProcId $procId " from $([IO.Path]::GetFileName($f))"
  }
  Remove-Item $f -Force -ErrorAction SilentlyContinue
}

# Porttisztítás (8082 a default prod port)
Write-Host "$LOG Port cleanup: $Port"
Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty OwningProcess -Unique |
  ForEach-Object { TryStop-ProcId $_ " (port $Port)" }

# Várunk max 10 mp-et, hogy felszabaduljon a port
$deadline = (Get-Date).AddSeconds(10)
while((Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline){
  Start-Sleep -Seconds 1
}

Write-Host "$LOG stopped."
exit 0


