# Version: 1.0.0
<#
.SYNOPSIS
    Restauration de l'environnement Claude Desktop (Windows) depuis une
    sauvegarde produite par Backup-ClaudeEnv.ps1.

.DESCRIPTION
    Restaure la configuration, les extensions, les plugins/skills marketplace et
    les skills perso dans %APPDATA%\Claude. Avant toute ecriture, le script fait
    une sauvegarde de securite de la configuration ACTUELLE. Claude Desktop doit
    etre FERME.

.PARAMETER Source
    Dossier de sauvegarde (claude-backup-...) OU son archive .zip.

.PARAMETER Yes
    N'affiche pas la demande de confirmation (mode non interactif).

.PARAMETER Force
    Ferme Claude Desktop automatiquement s'il est ouvert.

.EXAMPLE
    .\Restore-ClaudeEnv.ps1 -Source "D:\Backups\claude-backup-20260101-120000.zip"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Source,
    [switch]$Yes,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$Dst = Join-Path $env:APPDATA 'Claude'

function Info($m){ Write-Host $m }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Good($m){ Write-Host $m -ForegroundColor Green }

# --- 0. Claude est-il ouvert ? ---
$proc = Get-Process -Name 'Claude' -ErrorAction SilentlyContinue
if ($proc) {
    if ($Force) {
        Warn "Fermeture de Claude Desktop..."
        $proc | Stop-Process -Force
        Start-Sleep -Seconds 2
    } else {
        Write-Error "Claude Desktop est ouvert. Fermez-le (ou relancez avec -Force) avant de restaurer."
        exit 1
    }
}

# --- 1. Preparer la source (dezipper si besoin) ---
if (-not (Test-Path -LiteralPath $Source)) { Write-Error "Source introuvable : $Source"; exit 1 }
$temp = $null
if ($Source -match '\.zip$') {
    $temp = Join-Path $env:TEMP ("claude-restore-" + (Get-Date -Format 'yyyyMMddHHmmss'))
    New-Item -ItemType Directory -Path $temp -Force | Out-Null
    Info "Extraction de l'archive..."
    Expand-Archive -LiteralPath $Source -DestinationPath $temp -Force
    $backup = $temp
} else {
    $backup = $Source
}

if (-not (Test-Path -LiteralPath (Join-Path $backup 'MANIFEST.txt'))) {
    Warn "Attention : MANIFEST.txt absent de la source. Est-ce bien une sauvegarde Claude ?"
}

# --- 2. Confirmation ---
Write-Host ""
Write-Host "RESTAURATION" -ForegroundColor Cyan
Write-Host "  Depuis : $backup"
Write-Host "  Vers   : $Dst"
Write-Host "  La config actuelle sera d'abord sauvegardee (securite)."
Write-Host ""
if (-not $Yes) {
    $r = Read-Host "Confirmer la restauration ? (oui/non)"
    if ($r -notin @('oui','o','yes','y')) { Warn "Annule."; if ($temp){Remove-Item $temp -Recurse -Force}; exit 0 }
}

# --- 3. Sauvegarde de securite de l'existant ---
if (Test-Path -LiteralPath $Dst) {
    $safe = Join-Path $env:USERPROFILE ("Claude-Backups\_avant-restauration-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $safe -Force | Out-Null
    Get-ChildItem -LiteralPath $Dst -File -Filter 'claude_desktop_config.json*' -ErrorAction SilentlyContinue |
        ForEach-Object { Copy-Item $_.FullName $safe -Force }
    foreach ($f in @('config.json','Preferences','Local State')) {
        $p = Join-Path $Dst $f
        if (Test-Path -LiteralPath $p) { Copy-Item $p $safe -Force }
    }
    Good "Config actuelle sauvegardee dans : $safe"
} else {
    New-Item -ItemType Directory -Path $Dst -Force | Out-Null
}

# --- 4. Restauration des fichiers racine ---
Info "Restauration des fichiers de configuration..."
Get-ChildItem -LiteralPath $backup -File | Where-Object {
    $_.Name -notin @('MANIFEST.txt','_backup.log')
} | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $Dst -Force
    Info "  + $($_.Name)"
}

# --- 5. Restauration des dossiers ---
function Restore-Tree($name) {
    $from = Join-Path $backup $name
    if (-not (Test-Path -LiteralPath $from)) { return }
    $to = Join-Path $Dst $name
    & robocopy.exe $from $to '/E' '/R:1' '/W:1' '/NFL' '/NDL' '/NP' '/NJH' '/NJS' | Out-Null
    if ($LASTEXITCODE -ge 8) { Warn "  [ERREUR robocopy $LASTEXITCODE] $name" } else { Info "  + $name" }
}

Info "Restauration des extensions / plugins / skills..."
Restore-Tree 'Claude Extensions'
Restore-Tree 'Claude Extensions Settings'
Restore-Tree 'MarketPlace'
Restore-Tree 'local-agent-mode-sessions\skills-plugin'
Get-ChildItem -LiteralPath (Join-Path $backup 'local-agent-mode-sessions') -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin @('skills-plugin','_harvest') } | ForEach-Object {
        Restore-Tree (Join-Path 'local-agent-mode-sessions' $_.Name)
    }

if ($temp) { Remove-Item -LiteralPath $temp -Recurse -Force }

# --- 6. Etapes suivantes ---
Write-Host ""
Good "=== Restauration terminee ==="
Write-Host ""
Write-Host "ETAPES SUIVANTES :" -ForegroundColor Cyan
Write-Host "  1. Relancez Claude Desktop."
Write-Host "  2. Reconnectez-vous a votre compte si demande."
Write-Host "  3. Reconnectez les CONNECTEURS OAuth (Gmail, Agenda, Slack, GitHub,"
Write-Host "     Notion, Outlook...) via Reglages > Connecteurs : non restaurables"
Write-Host "     depuis les fichiers (jetons cote serveur)."
Write-Host "  4. Verifiez vos serveurs MCP locaux (voir claude_desktop_config.json) :"
Write-Host "     certains requierent Python (uvx) ou Node.js (npx) installes."
Write-Host "  5. Les skills marketplace volumineux exclus du mode COEUR se"
Write-Host "     re-installent depuis leur source ; skills-lock.json liste tout."

