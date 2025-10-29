Param(
  [ValidateSet("dev","prod","portfolio","all")] [string]$Target = "all"
)

. "$PSScriptRoot\_lib.ps1"
. "$PSScriptRoot\test.config.ps1"

$targets = switch ($Target) {
  "dev"        { $TestEnvs | Where-Object Name -eq "dev" }
  "prod"       { $TestEnvs | Where-Object Name -eq "prod" }
  "portfolio"  { $TestEnvs | Where-Object Name -eq "portfolio" }
  default      { $TestEnvs }
}

$allOk = $true
foreach ($t in $targets) {
  $ok = Test-Env -EnvDef $t
  $allOk = $allOk -and $ok
}

if (-not $allOk) { exit 2 } else { exit 0 }
