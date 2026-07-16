# Version: 1.0.0
<#
.SYNOPSIS
    Cree (ou supprime) une tache planifiee Windows qui lance la sauvegarde de
    l'environnement Claude Desktop a intervalle regulier.

.DESCRIPTION
    Enregistre une tache planifiee pour l'utilisateur courant (aucun droit
    administrateur requis). Par defaut : chaque vendredi a 12:00, en conservant
    les 10 dernieres sauvegardes. L'option StartWhenAvailable rattrape une
    execution manquee (PC eteint / en veille).

.PARAMETER Day
    Jour de la semaine : Monday..Sunday (defaut : Friday).

.PARAMETER Time
    Heure au format HH:mm (defaut : 12:00).

.PARAMETER Keep
    Nombre de sauvegardes a conserver (defaut : 10).

.PARAMETER ScriptPath
    Chemin du script Backup-ClaudeEnv.ps1. Defaut : le fichier situe a cote
    de ce script (meme dossier).

.PARAMETER Destination
    Dossier de destination des sauvegardes (transmis au script). Optionnel.

.PARAMETER TaskName
    Nom de la tache (defaut : ClaudeDesktopBackup).

.PARAMETER Full
    Passe l'option -Full au script (sauvegarde complete, plus volumineuse).

.PARAMETER Remove
    Supprime la tache planifiee au lieu de la creer.

.EXAMPLE
    .\Install-Schedule.ps1
    Cree la tache par defaut (vendredi 12:00, retention 10).

.EXAMPLE
    .\Install-Schedule.ps1 -Day Monday -Time 18:30 -Keep 20
    Chaque lundi a 18:30, conserve 20 sauvegardes.

.EXAMPLE
    .\Install-Schedule.ps1 -Remove
    Supprime la tache planifiee.
#>

[CmdletBinding()]
param(
    [ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')]
    [string]$Day = 'Friday',
    [string]$Time = '12:00',
    [int]$Keep = 10,
    [string]$ScriptPath = (Join-Path $PSScriptRoot 'Backup-ClaudeEnv.ps1'),
    [string]$Destination,
    [string]$TaskName = 'ClaudeDesktopBackup',
    [switch]$Full,
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

if ($Remove) {
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Tache '$TaskName' supprimee." -ForegroundColor Green
    } else {
        Write-Host "Aucune tache '$TaskName' a supprimer."
    }
    return
}

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    Write-Error "Script de sauvegarde introuvable : $ScriptPath (utilisez -ScriptPath)."
    exit 1
}
$ScriptPath = (Resolve-Path -LiteralPath $ScriptPath).Path

# Construction des arguments passes au script de sauvegarde
$scriptArgs = "-Keep $Keep"
if ($Full)        { $scriptArgs += ' -Full' }
if ($Destination) { $scriptArgs += (' -Destination "{0}"' -f $Destination) }

$argument = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}" {1}' -f $ScriptPath, $scriptArgs

$action   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argument
$trigger  = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Day -At ([datetime]$Time)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings `
    -Description "Sauvegarde reguliere de l'environnement Claude Desktop." -Force | Out-Null

$info = Get-ScheduledTaskInfo -TaskName $TaskName
Write-Host "Tache '$TaskName' creee : $Day $Time (retention $Keep)." -ForegroundColor Green
Write-Host ("Prochaine execution : " + $info.NextRunTime)

