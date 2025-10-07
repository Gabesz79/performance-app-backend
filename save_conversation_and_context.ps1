param(
  [switch]$WithDeps,
  [switch]$Interactive
)

$ErrorActionPreference = 'Continue'

function Write-Info($msg){ Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Save-Out($path, $scriptblock){
  try {
    & $scriptblock 2>&1 | Out-File -Encoding UTF8 $path
  } catch {
    "ERROR: $($_.Exception.Message)" | Out-File -Encoding UTF8 $path
  }
}

# 0) Repo gyökér meghatározása
$root = ""
try {
  $root = (git rev-parse --show-toplevel 2>$null).Trim()
} catch {}
if ([string]::IsNullOrWhiteSpace($root)) { $root = (Get-Location).Path }

Set-Location $root

# 1) Kimeneti mappa
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$out   = Join-Path $root ("_journal\" + $stamp)
New-Item -ItemType Directory -Force -Path $out | Out-Null

Write-Info "Kimeneti mappa: $out"

# 2) Git állapotok
Write-Info "Git állapot mentése..."
Save-Out (Join-Path $out 'git_status.txt')           { git status -sb -uno }
Save-Out (Join-Path $out 'git_branches.txt')         { git branch -vv }
Save-Out (Join-Path $out 'git_remote.txt')           { git remote show origin }
Save-Out (Join-Path $out 'git_head.txt')             { git rev-parse HEAD }
Save-Out (Join-Path $out 'git_log_last100.txt')      { git log -100 --graph --decorate --oneline }
Save-Out (Join-Path $out 'git_diff_unstaged.patch')  { git diff }
Save-Out (Join-Path $out 'git_diff_staged.patch')    { git diff --staged }
Save-Out (Join-Path $out 'git_ls_modified_untracked.txt') { git ls-files -m -o --exclude-standard }

# 3) Környezet
Write-Info "Környezeti információk mentése..."
Save-Out (Join-Path $out 'java_version.txt')   { java -version }
Save-Out (Join-Path $out 'gradle_version.txt') { .\gradlew --version }
Save-Out (Join-Path $out 'docker_version.txt') { docker version }

# 4) (Opcionális) Függőségek
if ($WithDeps) {
  Write-Info "Függőségek listázása (compileClasspath, testRuntimeClasspath)..."
  # Biztos ami biztos: külön JDK megadás, daemon nélkül
  $gradleJava = $env:JAVA_HOME
  $deps1 = { .\gradlew --no-daemon -Dorg.gradle.java.home="$gradleJava" dependencies --configuration compileClasspath }
  $deps2 = { .\gradlew --no-daemon -Dorg.gradle.java.home="$gradleJava" dependencies --configuration testRuntimeClasspath }
  Save-Out (Join-Path $out 'deps_compile.txt') $deps1
  Save-Out (Join-Path $out 'deps_test.txt')    $deps2
}

# 5) Projektfa (Windows tree)
Write-Info "Projektfa mentése..."
Save-Out (Join-Path $out 'tree.txt') { cmd /c tree /F }

# 6) Chat beillesztő fájl megnyitása
$chatFile = Join-Path $out 'CHAT_PASTE_HERE.md'
$chatTemplate = @"
# Chat napló (illeszd be ide a beszélgetést)

> Tipp: a böngészőben jelöld ki az egész beszélgetést (Ctrl+A/Ctrl+C),
> majd ide illeszd be (Ctrl+V). Ha több részletben van, nyugodtan többször
> is mentsd.

- Projekt: $(Split-Path -Leaf $root)
- Dátum: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- Ág: $(git rev-parse --abbrev-ref HEAD 2>$null)
- HEAD: $(git rev-parse HEAD 2>$null)

---
"@
Set-Content -Encoding UTF8 -Path $chatFile -Value $chatTemplate
Start-Process notepad.exe $chatFile

# 7) (Opcionális) Interaktív naplóablak
if ($Interactive) {
  Write-Info "Interaktív naplóablak indítása PowerShell Transcript-tel..."
  $transcriptPath = Join-Path $out 'console_transcript.txt'
  $psCmd = "Start-Transcript -Path `"$transcriptPath`" -Append; Set-Location `"$root`"; Write-Host 'Transzkript fut. Itt dolgozz; bezáráskor a napló lezárul.' -ForegroundColor Cyan"
  Start-Process powershell.exe -ArgumentList '-NoExit','-NoProfile','-Command', $psCmd
}

# 8) ZIP-be csomagolás (első kör)
Write-Info "Első ZIP készítése..."
$zip = Join-Path $root ("_journal\" + $stamp + ".zip")
Try {
  Compress-Archive -Path (Join-Path $out '*') -DestinationPath $zip -Force
  Write-Info "ZIP kész: $zip"
} Catch {
  Write-Warning "ZIP készítés sikertelen: $($_.Exception.Message)"
}

Write-Host "`nKÉSZ. A _journal mappában minden ott van." -ForegroundColor Green
Write-Host "Ha beillesztetted a chatet vagy befejezted az interaktív ablakot," `
         "újra lefuttathatod a ZIP-et így:" -ForegroundColor Yellow
Write-Host "  Compress-Archive -Path `"$out\*`" -DestinationPath `"$zip`" -Force" -ForegroundColor Yellow
