<#
.SYNOPSIS
    Fait evoluer la version du projet (semver) de maniere coherente.

.DESCRIPTION
    Met a jour, en un seul endroit logique : le fichier VERSION, l'en-tete
    "# Version:" des scripts, le badge du README, la marque de version du skill
    et le CHANGELOG. Reconstruit ensuite le skill.

    DRY-RUN par defaut : affiche ce qui serait modifie sans rien ecrire.
    Ajoutez -Apply pour ecrire reellement.

.PARAMETER NewVersion
    Nouvelle version au format semver, ex. 1.1.0

.PARAMETER Apply
    Applique les changements (sinon simple simulation).

.EXAMPLE
    .\Bump-Version.ps1 -NewVersion 1.1.0           # simulation
.EXAMPLE
    .\Bump-Version.ps1 -NewVersion 1.1.0 -Apply    # applique + rebuild skill
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$NewVersion,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$repo    = Split-Path -Parent $PSScriptRoot
$verFile = Join-Path $repo 'VERSION'
$old     = if (Test-Path -LiteralPath $verFile) { (Get-Content -Raw -Encoding UTF8 $verFile).Trim() } else { '0.0.0' }
$today   = Get-Date -Format 'yyyy-MM-dd'
$mode    = if ($Apply) { 'APPLIQUE' } else { 'SIMULATION (dry-run)' }

Write-Host "== Bump $old -> $NewVersion   [$mode] =="

function Edit-File($path, [scriptblock]$transform) {
    if (-not (Test-Path -LiteralPath $path)) { return }
    $orig = Get-Content -Raw -Encoding UTF8 $path
    $new  = & $transform $orig
    if ($new -ne $orig) {
        Write-Host ("  MAJ  " + (Split-Path -Leaf $path))
        if ($Apply) { Set-Content -LiteralPath $path -Value $new -Encoding UTF8 }
    }
}

# 1. VERSION
Write-Host "  VERSION -> $NewVersion"
if ($Apply) { Set-Content -LiteralPath $verFile -Value $NewVersion -Encoding UTF8 }

# 2. En-tete des scripts
Get-ChildItem (Join-Path $repo 'scripts') -File -Filter '*.ps1' | ForEach-Object {
    Edit-File $_.FullName { param($c) $c -replace '(?m)^# Version: .*$', "# Version: $NewVersion" }
}

# 3. Marque de version du skill
Edit-File (Join-Path $repo 'skill\SKILL.md') { param($c) $c -replace '<!-- version: .* -->', "<!-- version: $NewVersion -->" }

# 4. Badge du README
Edit-File (Join-Path $repo 'README.md') { param($c) $c -replace 'badge/version-[0-9.]+-brightgreen', "badge/version-$NewVersion-brightgreen" }

# 5. CHANGELOG : promeut [Unreleased] en nouvelle version
Edit-File (Join-Path $repo 'CHANGELOG.md') { param($c)
    $c -replace '## \[Unreleased\]', "## [Unreleased]`r`n`r`n## [$NewVersion] - $today"
}

Write-Host ''
if ($Apply) {
    Write-Host 'Reconstruction du skill...'
    & 'powershell.exe' -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'tools\Build-Skill.ps1') | Out-Null
    Write-Host "OK - version $NewVersion appliquee."
    Write-Host "Etapes : completez le CHANGELOG, commit, puis : git tag v$NewVersion"
} else {
    Write-Host 'Dry-run : rien ecrit. Relancez avec -Apply pour appliquer.'
}
