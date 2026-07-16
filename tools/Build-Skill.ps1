<#
.SYNOPSIS
    (Re)construit dist/desktop-env-backup.skill a partir de skill/SKILL.md et
    des scripts de scripts/.

.DESCRIPTION
    Assemble une archive .skill dont les entrees utilisent des separateurs "/"
    (exigence de l'installeur de skills). Les noms d'entrees sont construits
    explicitement (aucun calcul de chemin relatif), donc portable sur toute
    machine y compris les runners CI. Source unique de verite : scripts/.
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

# Table : nom dans l'archive (avec "/") -> fichier source
$map = [ordered]@{}
$map['SKILL.md'] = (Join-Path $repo 'skill\SKILL.md')
Get-ChildItem (Join-Path $repo 'scripts') -File -Filter '*.ps1' | Sort-Object Name | ForEach-Object {
    $map['scripts/' + $_.Name] = $_.FullName
}

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
