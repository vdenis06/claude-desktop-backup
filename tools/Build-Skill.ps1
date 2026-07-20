<#
.SYNOPSIS
    (Re)construit dist/desktop-env-backup.skill a partir de
    skills/desktop-env-backup/SKILL.md et des scripts de scripts/.

.DESCRIPTION
    Assemble une archive .skill dont les entrees utilisent des separateurs "/"
    (exigence de l'installeur de skills). Noms d'entrees construits explicitement
    (portable, y compris sur les runners CI). Source unique : scripts/.
#>

[CmdletBinding()]
param(
    [string]$Name = 'desktop-env-backup'
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $repo 'dist'
$out  = Join-Path $dist ($Name + '.skill')
New-Item -ItemType Directory -Force -Path $dist | Out-Null

$map = [ordered]@{}
$map['SKILL.md'] = (Join-Path $repo 'skills\desktop-env-backup\SKILL.md')
Get-ChildItem (Join-Path $repo 'local') -File -Filter '*.py' | Sort-Object Name | ForEach-Object {
    $map['local/' + $_.Name] = $_.FullName
}
Get-ChildItem (Join-Path $repo 'cloud') -File -Filter '*.md' | Sort-Object Name | ForEach-Object {
    $map['cloud/' + $_.Name] = $_.FullName
}
$sched = Join-Path $repo 'scripts\Install-Schedule.ps1'
if (Test-Path -LiteralPath $sched) { $map['scripts/Install-Schedule.ps1'] = $sched }

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Force }

$zip = [System.IO.Compression.ZipFile]::Open($out, 'Create')
try {
    foreach ($arc in $map.Keys) {
        $src = $map[$arc]
        if (-not (Test-Path -LiteralPath $src)) { throw "Fichier source introuvable : $src" }
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $src, $arc) | Out-Null
        Write-Host "  + $arc"
    }
} finally {
    $zip.Dispose()
}

Write-Host ""
Write-Host "OK  $out" -ForegroundColor Green
