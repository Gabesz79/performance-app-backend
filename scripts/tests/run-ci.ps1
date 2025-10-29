Param([switch]$NoClean)

. "$PSScriptRoot\_lib.ps1"
Write-Log INFO "=== CI tesztek (Gradle) indítása ==="
$ok = Run-GradleTests -NoClean:$NoClean
if (-not $ok) { exit 1 } else { exit 0 }
