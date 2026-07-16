# Version: 1.0.0
<#
.SYNOPSIS
    Sauvegarde complete de l'environnement Claude Desktop (Windows).

.DESCRIPTION
    Copie la configuration, les plugins/skills marketplace, les extensions DXT,
    les skills perso et (en option) les sessions/projets vers un dossier date,
    puis produit un manifeste et une archive .zip.

    Les caches regenerables (vm_bundles, Cache, Code Cache, GPUCache, VM Claude
    Code, logs...) ne sont volontairement PAS copies : ils se recreent seuls.

    ATTENTION : claude_desktop_config.json peut contenir des SECRETS en clair
    (tokens, mots de passe des serveurs MCP). La sauvegarde les inclut pour une
    restauration a l'identique. Stockez le dossier / le .zip dans un endroit sur
    (disque chiffre, coffre) et ne le partagez pas tel quel.

.PARAMETER Destination
    Dossier ou creer la sauvegarde. Defaut : %USERPROFILE%\Claude-Backups

.PARAMETER Full
    Inclut aussi les elements volumineux : les gros skills marketplace et
    l'integralite de local-agent-mode-sessions. Sans ce commutateur, la
    sauvegarde reste legere tout en capturant toute la CONFIGURATION.

.PARAMETER MaxItemMB
    En mode "coeur", les skills marketplace dont la taille depasse cette valeur
    (defaut 200 Mo) sont exclus (re-installables via skills-lock.json). Sans
    effet avec -Full.

.PARAMETER NoZip
    Ne cree pas d'archive .zip (laisse seulement le dossier).

.PARAMETER Keep
    Nombre de sauvegardes a conserver (defaut : 10). Les plus anciennes
    (dossiers ET .zip) sont supprimees a la fin. Mettre 0 pour tout garder.

.EXAMPLE
    .\Backup-ClaudeEnv.ps1
.EXAMPLE
    .\Backup-ClaudeEnv.ps1 -Full -Destination "D:\Backups\Claude"
#>

[CmdletBinding()]
param(
    [string]$Destination = (Join-Path $env:USERPROFILE 'Claude-Backups'),
    [switch]$Full,
    [int]$MaxItemMB = 200,
    [switch]$NoZip,
    [int]$Keep = 10
)

$ErrorActionPreference = 'Stop'
$Src = Join-Path $env:APPDATA 'Claude'

if (-not (Test-Path -LiteralPath $Src)) {
    Write-Error "Dossier Claude introuvable : $Src"
    exit 1
}

$stamp   = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup  = Join-Path $Destination "claude-backup-$stamp"
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$logFile = Join-Path $backup '_backup.log'

function Log($msg) {
    $line = "{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg
    Write-Host $line
    Add-Content -LiteralPath $logFile -Value $line
}

Log "=== Sauvegarde environnement Claude ==="
Log "Machine     : $env:COMPUTERNAME"
Log "Source      : $Src"
Log "Destination : $backup"
Log ("Mode        : " + $(if ($Full) { 'FULL (tout inclus)' } else { 'COEUR (config + customisation)' }))
Log ""

# --- 1. Fichiers de config / etat (racine) ---
$rootFiles = @(
    'config.json','Preferences','Local State','window-state.json',
    'git-worktrees.json','plan-usage-history.json','cowork-enabled-cli-ops.json',
    'extensions-installations.json','extensions-blocklist.json','buddy-tokens.json','ant-did'
)
Log "--- Fichiers de configuration racine ---"
Get-ChildItem -LiteralPath $Src -File -Filter 'claude_desktop_config.json*' -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $backup -Force
    Log ("  + " + $_.Name)
}
foreach ($f in $rootFiles) {
    $p = Join-Path $Src $f
    if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination $backup -Force; Log "  + $f" }
}
Log ""

function Copy-Tree($from, $toName, [string[]]$excludeDirs) {
    if (-not (Test-Path -LiteralPath $from)) { Log "  (absent) $toName"; return }
    $to = Join-Path $backup $toName
    $args = @($from, $to, '/E', '/R:1', '/W:1', '/NFL', '/NDL', '/NP', '/NJH', '/NJS')
    if ($excludeDirs) { $args += '/XD'; $args += $excludeDirs }
    & robocopy.exe @args | Out-Null
    if ($LASTEXITCODE -ge 8) { Log "  [ERREUR robocopy $LASTEXITCODE] $toName" } else { Log "  + $toName" }
}

# --- 2. Extensions DXT ---
Log "--- Extensions ---"
Copy-Tree (Join-Path $Src 'Claude Extensions')          'Claude Extensions'
Copy-Tree (Join-Path $Src 'Claude Extensions Settings') 'Claude Extensions Settings'
Log ""

# --- 3. MarketPlace (plugins + skills marketplace) ---
Log "--- MarketPlace (plugins & skills) ---"
if ($Full) {
    Copy-Tree (Join-Path $Src 'MarketPlace') 'MarketPlace'
} else {
    # Exclut dynamiquement les skills volumineux (> MaxItemMB), re-installables via skills-lock.json
    $excludeNames = @()
    foreach ($rel in @('MarketPlace\.agents\skills','MarketPlace\.claude\skills')) {
        $parent = Join-Path $Src $rel
        if (Test-Path -LiteralPath $parent) {
            Get-ChildItem -LiteralPath $parent -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $mb = (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
                if ($mb -gt $MaxItemMB) { $excludeNames += $_.Name }
            }
        }
    }
    $excludeNames = $excludeNames | Select-Object -Unique
    Copy-Tree (Join-Path $Src 'MarketPlace') 'MarketPlace' $excludeNames
    if ($excludeNames.Count) { Log ("    (skills volumineux exclus > $MaxItemMB Mo : " + ($excludeNames -join ', ') + ")") }
}
Log ""

# --- 4. Skills perso + memoire + metadonnees de projets ---
Log "--- Skills perso & projets (local-agent-mode-sessions) ---"
$lams = Join-Path $Src 'local-agent-mode-sessions'
Copy-Tree (Join-Path $lams 'skills-plugin') (Join-Path 'local-agent-mode-sessions' 'skills-plugin')
if (Test-Path -LiteralPath $lams) {
    $harvest = Join-Path $backup 'local-agent-mode-sessions\_harvest'
    & robocopy.exe $lams $harvest 'metadata.json' 'memory.md' 'syncs.json' 'CLAUDE.md' '/S' '/R:1' '/W:1' '/NFL' '/NDL' '/NP' '/NJH' '/NJS' | Out-Null
    Log "  + local-agent-mode-sessions\_harvest (metadata.json, memory.md, syncs.json, CLAUDE.md)"
}
if ($Full) {
    Get-ChildItem -LiteralPath $lams -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'skills-plugin' } | ForEach-Object {
            Copy-Tree $_.FullName (Join-Path 'local-agent-mode-sessions' $_.Name)
        }
}
Log ""

# --- 5. Manifeste ---
Log "--- Manifeste ---"
$manifest = Join-Path $backup 'MANIFEST.txt'
$dcConfig = Join-Path $Src 'claude_desktop_config.json'
$mcpNames = @()
if (Test-Path -LiteralPath $dcConfig) {
    try {
        $cfg = Get-Content -LiteralPath $dcConfig -Raw | ConvertFrom-Json
        if ($cfg.mcpServers) { $mcpNames = $cfg.mcpServers.PSObject.Properties.Name }
    } catch { }
}
$skillsLock = Join-Path $Src 'MarketPlace\skills-lock.json'
$skillCount = 0
if (Test-Path -LiteralPath $skillsLock) {
    try { $skillCount = (Get-Content -LiteralPath $skillsLock -Raw | ConvertFrom-Json).skills.PSObject.Properties.Count } catch { }
}
$lines = @()
$lines += "SAUVEGARDE ENVIRONNEMENT CLAUDE DESKTOP"
$lines += "======================================="
$lines += "Date          : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$lines += "Machine       : $env:COMPUTERNAME"
$lines += "Utilisateur   : $env:USERNAME"
$lines += ("Mode          : " + $(if ($Full) { 'FULL' } else { 'COEUR' }))
$lines += ""
$lines += "Serveurs MCP locaux (claude_desktop_config.json) :"
if ($mcpNames.Count) { $mcpNames | ForEach-Object { $lines += "  - $_" } } else { $lines += "  (aucun)" }
$lines += ""
$lines += "Skills marketplace installes (skills-lock.json) : $skillCount"
$lines += ""
$lines += "RAPPEL - Connecteurs OAuth : geres cote claude.ai, PAS dans ces"
$lines += "fichiers. A reconnecter manuellement apres reinstallation."
$lines += ""
$lines += "Contenu du dossier :"
Get-ChildItem -LiteralPath $backup | ForEach-Object { $lines += "  - $($_.Name)" }
Set-Content -LiteralPath $manifest -Value $lines -Encoding UTF8
Log "  + MANIFEST.txt"
Log ""

# --- 6. Taille + zip ---
$sizeMB = [math]::Round((Get-ChildItem -LiteralPath $backup -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB, 1)
Log "Taille dossier : $sizeMB Mo"
if (-not $NoZip) {
    $zip = "$backup.zip"
    Log "Compression -> $zip ..."
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    Compress-Archive -Path (Join-Path $backup '*') -DestinationPath $zip -CompressionLevel Optimal
    $zipMB = [math]::Round((Get-Item -LiteralPath $zip).Length / 1MB, 1)
    Log "Archive creee  : $zip ($zipMB Mo)"
}

# --- 7. Retention ---
if ($Keep -gt 0) {
    Log ""
    Log "--- Retention (max $Keep) ---"
    $folders = Get-ChildItem -LiteralPath $Destination -Directory -Filter 'claude-backup-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($folders.Count -gt $Keep) {
        $folders | Select-Object -Skip $Keep | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            Log "  - supprime (dossier) $($_.Name)"
        }
    }
    $zips = Get-ChildItem -LiteralPath $Destination -File -Filter 'claude-backup-*.zip' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($zips.Count -gt $Keep) {
        $zips | Select-Object -Skip $Keep | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            Log "  - supprime (zip) $($_.Name)"
        }
    }
    Log ("  Sauvegardes conservees : " + [math]::Min($folders.Count, $Keep) + " (dossiers)")
}

Log ""
Log "=== Sauvegarde terminee ==="
Write-Host ""
Write-Host "OK  Sauvegarde : $backup" -ForegroundColor Green
if (-not $NoZip) { Write-Host "OK  Archive    : $backup.zip" -ForegroundColor Green }

