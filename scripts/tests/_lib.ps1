Param()

function New-Log {
  param([string]$Prefix="test-run")
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $path = ".run\tests\logs\$Prefix-$ts.log"
  New-Item -ItemType File -Force $path | Out-Null
  return (Resolve-Path $path).Path
}

$script:LOG = $null
function Write-Log {
  param([ValidateSet("INFO","WARN","ERR","OK")] [string]$Level="INFO",
        [Parameter(Mandatory)][string]$Message)
  $line = "[{0}] {1}  {2}" -f (Get-Date -Format "u"), $Level, $Message
  if (-not $script:LOG) { $script:LOG = New-Log }
  Add-Content -Encoding UTF8 -Path $script:LOG -Value $line
  $color = switch ($Level) { "OK" {"Green"} "WARN" {"Yellow"} "ERR" {"Red"} default {"Gray"} }
  Write-Host $line -ForegroundColor $color
}

function Assert {
  param([bool]$Condition, [string]$OkMsg="", [string]$ErrMsg="")
  if ($Condition) { Write-Log OK ($OkMsg -ne "" ? $OkMsg : "OK") ; return $true }
  else            { Write-Log ERR ($ErrMsg -ne "" ? $ErrMsg : "HIBA") ; return $false }
}

function Invoke-Http {
  param(
    [Parameter(Mandatory)][string]$Url,
    [string]$User = $null,
    [string]$Pass = $null,
    [int]$TimeoutSec = 5,
    [switch]$ReturnRaw
  )
  try {
    $params = @{ Uri=$Url; Method='GET'; TimeoutSec=$TimeoutSec; ErrorAction='Stop' }
    if ($User -and $Pass) { $params.Authentication='Basic'; $params.Credential=[pscredential]::new($User,(ConvertTo-SecureString $Pass -AsPlainText -Force)) }
    $resp = Invoke-WebRequest @params
    $body = $resp.Content
    $json = $null
    try { $json = $body | ConvertFrom-Json -ErrorAction Stop } catch {}
    return [pscustomobject]@{
      Success    = $true
      StatusCode = $resp.StatusCode
      Body       = $body
      Json       = $json
    }
  } catch {
    if ($ReturnRaw) { return $_ }
    return [pscustomobject]@{ Success=$false; StatusCode=$null; Body=$null; Json=$null; Error=$_.Exception.Message }
  }
}

function Wait-Until-Healthy {
  param(
    [Parameter(Mandatory)][string]$BaseUrl,
    [string]$HealthzPath = "/api/healthz",
    [string]$ActuatorPath = "/actuator/health",
    [string]$User=$null, [string]$Pass=$null,
    [int]$MaxWaitSec=90
  )
  $deadline = (Get-Date).AddSeconds($MaxWaitSec)
  do {
    # 1) /api/healthz == "ok"
    $h = Invoke-Http -Url ($BaseUrl.TrimEnd('/') + $HealthzPath) -User $User -Pass $Pass
    if ($h.Success -and ($h.Body.Trim().ToLower() -eq "ok")) { return $true }

    # 2) actuator contains "UP" (best-effort, lehet 401/404 prodon)
    $a = Invoke-Http -Url ($BaseUrl.TrimEnd('/') + $ActuatorPath) -User $User -Pass $Pass
    if ($a.Success -and $a.Body -match '"status"\s*:\s*"UP"') { return $true }

    Start-Sleep -Milliseconds 800
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Run-GradleTests {
  param([switch]$NoClean)
  $gradlew = (Test-Path .\gradlew.bat) ? ".\gradlew.bat" : "./gradlew"
  $env:JAVA_TOOL_OPTIONS='-Djava.net.preferIPv4Stack=true'
  $args = @()
  if (-not $NoClean) { $args += "clean" }
  $args += "test"
  Write-Log INFO "Gradle tesztek futtatása: $gradlew $($args -join ' ')"
  & $gradlew @args
  $ok = $LASTEXITCODE -eq 0
  Assert $ok "Gradle tesztek: SIKERES" "Gradle tesztek: HIBA (exit=$LASTEXITCODE)" | Out-Null
  return $ok
}

function Test-Env {
  param(
    [Parameter(Mandatory)][hashtable]$EnvDef
  )
  $name    = $EnvDef.Name
  $start   = $EnvDef.Start
  $stop    = $EnvDef.Stop
  $baseUrl = $EnvDef.BaseUrl
  $user    = $EnvDef.BasicUser
  $pass    = $EnvDef.BasicPass

  Write-Log INFO "[$name] környezet teszt indul"
  if ($start -and (Test-Path $start)) {
    Write-Log INFO "[$name] start: $start"
    & $start | Out-Null
  } elseif ($start) {
    Write-Log WARN "[$name] start script nem található: $start (átugorjuk az indítást)"
  }

  $ready = Wait-Until-Healthy -BaseUrl $baseUrl -User $user -Pass $pass -MaxWaitSec 120
  if (-not (Assert $ready "[$name] HEALTZ/ACTUATOR él" "[$name] nem állt fel időben")) { 
    if ($stop -and (Test-Path $stop)) { & $stop | Out-Null }
    return $false
  }

  # --- Smoke vizsgálatok ---
  $ok = $true

  # /api/healthz == ok
  $h = Invoke-Http -Url ($baseUrl + "/api/healthz") -User $user -Pass $pass
  $ok = $ok -and (Assert ($h.Success -and $h.Body.Trim().ToLower() -eq "ok") "[$name] /api/healthz == ok" "[$name] /api/healthz HIBA")

  # Swagger UI elérhető
  $sw = Invoke-Http -Url ($baseUrl + "/swagger-ui/index.html") -User $user -Pass $pass
  $ok = $ok -and (Assert ($sw.Success -and $sw.StatusCode -eq 200) "[$name] Swagger UI 200" "[$name] Swagger UI nem elérhető")

  # Workouts summary (best-effort)
  $from = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
  $to   = (Get-Date).ToString("yyyy-MM-dd")
  $su   = Invoke-Http -Url ($baseUrl + "/api/workouts/summary?from=$from&to=$to") -User $user -Pass $pass
  $ok = $ok -and (Assert ($su.Success -and $su.Json -and ($su.Json.PSObject.Properties.Name -contains "totalSessions")) "[$name] /workouts/summary válasz OK" "[$name] /workouts/summary HIBA")

  if ($stop -and (Test-Path $stop)) {
    Write-Log INFO "[$name] stop: $stop"
    & $stop | Out-Null
  }

  return $ok
}
