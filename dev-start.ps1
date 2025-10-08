#Requires -Version 5.1
# performance-app-backend DEV start (PowerShell, recommended)
param(
  [int]$HealthTimeoutSec = 120
)
$ErrorActionPreference = "Stop"
if (-not $env:SPRING_PROFILES_ACTIVE) { $env:SPRING_PROFILES_ACTIVE = "local" }
$script:LOG = "[DEV]"

function Log($m){ Write-Host $m }
function Warn($m){ Write-Warning $m }
function Fail($m){ Write-Error $m; exit 1 }

Set-Location -LiteralPath $PSScriptRoot

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

# 1) Docker Desktop
try { docker info | Out-Null } catch {
  Warn "$LOG Docker not ready. Starting Docker Desktop..."
  $dockerExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
  if(-not (Test-Path $dockerExe)){ Fail "$LOG Docker Desktop not found." }
  Start-Process -FilePath $dockerExe | Out-Null
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while($sw.Elapsed.TotalSeconds -lt 90){
    Start-Sleep -Seconds 3
    try { docker info | Out-Null; break } catch {}
  }
  if($sw.Elapsed.TotalSeconds -ge 90){ Fail "$LOG Docker engine didn't become ready in time." }
}
Log "$LOG Docker is ready."

# 2) compose up
if(Test-Path "docker-compose.yml"){
  Log "$LOG docker compose up -d"
  docker compose up -d | Out-Null
}else{
  Warn "$LOG docker-compose.yml not found (skipping)"
}

# 3) bootRun (spawn + PID file)
$runDir = Join-Path $PSScriptRoot ".run"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
$proc = Start-Process -FilePath ".\gradlew.bat" -ArgumentList "--no-daemon","bootRun" -NoNewWindow -PassThru
$proc.Id | Set-Content -Path (Join-Path $runDir "bootrun.pid")
Log "$LOG bootRun PID=$($proc.Id)"

# 4) health
$deadline = (Get-Date).AddSeconds($HealthTimeoutSec)
$health = "http://localhost:8080/api/healthz"
while((Get-Date) -lt $deadline){
  try{
    $r = Invoke-WebRequest $health -TimeoutSec 3 -UseBasicParsing
    if($r.StatusCode -eq 200){
      Log "$LOG health OK: $($r.Content)"
      Log "$LOG Swagger UI: http://localhost:8080/swagger-ui.html"
      exit 0
    }
  }catch{}
  Start-Sleep -Seconds 3
  Log "$LOG waiting app health..."
}
Warn "$LOG health check timeout; app may still be booting. Try the Swagger UI manually."
exit 0
