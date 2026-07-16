<#
.SYNOPSIS
    (Re)construit dist/desktop-env-backup.skill a partir de skill/SKILL.md et
    des scripts de scripts/.

.DESCRIPTION
    Assemble une archive .skill dont les entrees utilisent des separateurs "/"
    (exigence de l'installeur de skills). A lancer apres toute modification de
    SKILL.md ou des scripts. Source unique de verite : le dossier scripts/.
#>

[CmdletBinding()]
param(
    [string]$Name = 'desktop-env-backup'
)

$ErrorActionPreference = 'Stop'
$repo  = Split-Path -Parent $PSScriptRoot          # racine du depot (parent de tools/)
$build = Join-Path $env:TEMP ("skillbuild-" + [guid]::NewGuid().ToString('N'))
$dist  = Join-Path $repo 'dist'
$out   = Join-Path $dist ($Name + '.skill')

New-Item -ItemType Directory -Force -Path (Join-Path $build 'scripts') | Out-Null
New-Item -ItemType Directory -Force -Path $dist | Out-Null

Copy-Item (Join-Path $repo 'skill\SKILL.md') (Join-Path $build 'SKILL.md')
Get-ChildItem (Join-Path $repo 'scripts') -File -Filter '*.ps1' |
    ForEach-Object { Copy-Item $_.FullName (Join-Path $build 'scripts') }

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Force }
$base = (Resolve-Path -LiteralPath $build).Path
$zip = [System.IO.Compression.ZipFile]::Open($out, 'Create')
try {
    Get-ChildItem -LiteralPath $build -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($base.Length).TrimStart('\','/').Replace('\','/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $rel) | Out-Null
        Write-Host "  + $rel"
    }
} finally { $zip.Dispose() }

Remove-Item -LiteralPath $build -Recurse -Force
Write-Host ""
Write-Host "OK  $out" -ForegroundColor Green
