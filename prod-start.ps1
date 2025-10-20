#Requires -Version 5.1
# performance-app-backend PROD start (PowerShell)
param(
  [int]$HealthTimeoutSec = 120
)
$ErrorActionPreference = "Stop"
$script:LOG = "[PROD]"

function Log($m){ Write-Host $m }
function Warn($m){ Write-Warning $m }
function Fail($m){ Write-Error $m; exit 1 }

Set-Location -LiteralPath $PSScriptRoot

# --- LÉNYEG: kényszerítsük a PROD környezetet mindig prod/8082-re ---
$env:SPRING_PROFILES_ACTIVE = "prod"
if (-not $env:SERVER_PORT) { $env:SERVER_PORT = "8082" }

$port = [int]$env:SERVER_PORT
$health = "http://localhost:$port/api/healthz"
Write-Host "[PROD] Profile: $env:SPRING_PROFILES_ACTIVE"
Write-Host "[PROD] Port: $port"
Write-Host "[PROD] Health URL: $health"

# 0) JDK
$JdkCandidates = @(
  "C:\Program Files\Java\jdk-21",
  "C:\Program Files\Eclipse Adoptium\jdk-21",
  "C:\Program Files\Zulu\zulu-21",
  "C:\Program Files (x86)\Java\jdk-21"
) + @($env:JAVA_HOME) | Where-Object { $_ } | Select-Object -Unique

$javaHome = $null
foreach($c in $JdkCandidates){
  if(Test-Path "$c\bin\javac.exe"){ $javaHome = $c; break }
}
if(-not $javaHome){ Fail "$LOG JDK 21 not found. Please install." }

$env:JAVA_HOME = $javaHome
$env:GRADLE_JAVA_HOME = $javaHome
$env:PATH = "$javaHome\bin;$env:PATH"
$env:JAVA_TOOL_OPTIONS = "-Djava.net.preferIPv4Stack=true"
Log "$LOG JAVA_HOME=$javaHome"
& java -version

# (NINCS Docker compose: a DB-t a dev-compose indítja, vagy saját DB-det használod)

# Indítás
# 3) bootRun (spawn + PID file) — KIMENET FÁJLBA
$runDir = Join-Path $PSScriptRoot ".run"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
$logOut = Join-Path $runDir "bootrun.out"
$logErr = Join-Path $runDir "bootrun.err"

$proc = Start-Process -FilePath ".\gradlew.bat" `
  -ArgumentList "--no-daemon","bootRun" `
  -WorkingDirectory $PSScriptRoot `
  -RedirectStandardOutput $logOut `
  -RedirectStandardError  $logErr `
  -WindowStyle Hidden `
  -PassThru

$proc.Id | Set-Content -Path (Join-Path $runDir "bootrun.pid")
Log "$LOG bootRun PID=$($proc.Id)"
Log "$LOG Inditas: http://localhost:$($env:SERVER_PORT)  (Swagger: /swagger-ui/index.html)"

# Health check
$deadline = (Get-Date).AddSeconds($HealthTimeoutSec)
$port = $env:SERVER_PORT
$health = "http://localhost:$port/actuator/health"
while((Get-Date) -lt $deadline){
  try{
    $r = Invoke-WebRequest $health -TimeoutSec 3 -UseBasicParsing
    if($r.StatusCode -eq 200){
      Log "$LOG health OK: $($r.Content)"
      Log "$LOG App:     http://localhost:$port/"
      Log "$LOG Swagger: http://localhost:$port/swagger-ui/index.html"
      exit 0
    }
  }catch{}
  Start-Sleep -Seconds 3
  Log "$LOG waiting app health..."
}
Warn "$LOG health check timeout; showing last lines from logs..."
if (Test-Path $logErr) { Write-Host "---- bootrun.err (last 120) ----"; Get-Content $logErr -Tail 120 }
if (Test-Path $logOut) { Write-Host "---- bootrun.out (last 60) ----";  Get-Content $logOut -Tail 60  }
exit 0
