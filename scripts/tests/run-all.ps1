Param(
  [switch]$SkipCI,
  [switch]$OnlyCI,
  [ValidateSet("dev","prod","portfolio","all")] [string]$Env = "all"
)

. "$PSScriptRoot\_lib.ps1"
. "$PSScriptRoot\test.config.ps1"

Write-Log INFO "=== Teljes tesztcsomag indul ==="

$overallOk = $true

if ($OnlyCI) {
  Write-Log INFO "Csak CI tesztek futnak (Gradle)."
  & "$PSScriptRoot\run-ci.ps1"
  exit $LASTEXITCODE
}

if (-not $SkipCI -and $Global:RunCI) {
  & "$PSScriptRoot\run-ci.ps1"
  if ($LASTEXITCODE -ne 0) { $overallOk = $false }
} else {
  Write-Log WARN "CI rész kihagyva (SkipCI vagy RunCI=false)."
}

# Környezeti tesztek
$envList = @()
if ($Global:RunDev)       { $envList += "dev" }
if ($Global:RunProd)      { $envList += "prod" }
if ($Global:RunPortfolio) { $envList += "portfolio" }

switch ($Env) {
  "dev"        { $envList = @("dev") }
  "prod"       { $envList = @("prod") }
  "portfolio"  { $envList = @("portfolio") }
  default      { } # all
}

foreach ($e in $envList) {
  & "$PSScriptRoot\test-env.ps1" -Target $e
  if ($LASTEXITCODE -ne 0) { $overallOk = $false }
}

Write-Log INFO ("=== Összegzés: " + ($(if($overallOk){"SIKERES"}else{"HIBA"})) + " ===")
if (-not $overallOk) { exit 3 } else { exit 0 }
