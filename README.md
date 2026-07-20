# Claude Desktop Backup / Sauvegarde Claude Desktop

![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-blue)
![Python](https://img.shields.io/badge/Python-3.8%2B-3776AB)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-2.0.0-brightgreen)
[![Made with Claude](https://img.shields.io/badge/Made%20with-Claude-D97757)](https://claude.ai)

Back up and restore your **Claude Desktop** environment, and rebuild it on another
machine or account. Cross-platform (Windows, macOS, Linux), 100 % local — nothing
is sent over the network.

> English first, français plus bas.

## English

### What it does
A Claude setup has two halves, and this tool covers both:
- **Local half** (files on disk) — `local/` Python scripts back up and restore the
  config, MCP servers, DXT extensions, marketplace plugins & skills, and personal
  skills. Fully automated.
- **Account half** (server side: Projects, connectors, installed plugins) — `cloud/`
  bilingual runbooks to inventory and rebuild it, since it cannot be copied from disk.

### Requirements
- **Python 3.8+**. Config auto-detected per OS (`%APPDATA%\Claude`,
  `~/Library/Application Support/Claude`, `~/.config/Claude`); override with
  `CLAUDE_CONFIG_DIR`.
- For the **skill**: the **Desktop Commander** MCP in Claude.

### Backup
```
python local/claude_backup.py
```
Creates `~/Claude-Backups/claude-backup-<date>/` + a `.zip`.

| Option | Effect |
|---|---|
| `--full` | Include large skills and full session history. |
| `--destination DIR` | Change the destination folder. |
| `--keep N` | Backups to keep (default 10; `0` = unlimited). |
| `--max-item-mb N` | Core-mode size threshold for large skills (default 200). |
| `--no-zip` | Skip the archive. |
| `--include-secrets` | Keep MCP secrets inline (not recommended for sharing). |

### Secrets
By default, MCP secrets in `claude_desktop_config.json` are moved to a separate
`secrets.json`, **excluded from the `.zip`**. The `.zip` is shareable; the backup
folder (which holds `secrets.json`) is not — store it safely.

### Restore
Close Claude Desktop first, then:
```
# Same account / new machine (reinjects secrets)
python local/claude_restore.py <folder-or-zip> --mode same-machine

# New account / new environment (skips identity files, keeps redacted config)
python local/claude_restore.py <folder-or-zip> --mode new-environment
```
`--force` closes Claude if open; `--yes` skips the prompt; `--target DIR` restores
elsewhere (for testing). Then follow `cloud/RESTORE.md` for the account side.

### Account side (Projects, plugins, connectors)
The scripts cover local files only. To capture and rebuild the account half, follow
the runbooks: `cloud/export-inventory.md`, `cloud/export-project.md`,
`cloud/RESTORE.md`.

### Install the skill
- **Marketplace**: `/plugin marketplace add vdenis06/claude-desktop-backup` then
  `/plugin install desktop-env-backup@vdenis06-tools`.
- **.skill file**: import `dist/desktop-env-backup.skill` via Settings → Capabilities
  → Skills. Then say "back up my Claude environment".

### Scheduling & limits
Scheduling is Windows-only for now via `scripts/Install-Schedule.ps1` (weekly, no
admin); cron/launchd are not yet ported. OAuth tokens and conversations are never
exportable (reconnect / re-auth). Full Project enumeration needs the web app or
account export. A Project's description and custom instructions are re-entered by
hand on restore.

### Security & license
`claude_desktop_config.json` may contain plaintext secrets — keep the backup folder
safe and, on a leak, revoke and regenerate them. Author: **vdenis06**. MIT. Made
with Claude.

## Français

Sauvegardez et restaurez votre environnement **Claude Desktop**, et reconstruisez-le
sur une autre machine ou un autre compte. Multi-plateforme (Windows, macOS, Linux),
100 % local.

### Ce que fait l'outil
Deux moitiés, toutes deux couvertes : la **moitié locale** (`local/`, scripts Python :
config, serveurs MCP, extensions, plugins et skills) et la **moitié compte** (`cloud/`,
runbooks : Projets, connecteurs, plugins installés), qui ne se copie pas depuis le disque.

### Prérequis
**Python 3.8+**. Config détectée par OS (override `CLAUDE_CONFIG_DIR`). Pour le skill :
le MCP **Desktop Commander**.

### Sauvegarde
`python local/claude_backup.py` → `~/Claude-Backups/claude-backup-<date>/` + `.zip`.
Options : `--full`, `--destination`, `--keep`, `--max-item-mb`, `--no-zip`,
`--include-secrets`.

### Secrets
Les secrets MCP sont isolés dans `secrets.json`, **hors du `.zip`** par défaut. Le
`.zip` est partageable ; le dossier (avec `secrets.json`) ne l'est pas.

### Restauration
Fermer Claude, puis `python local/claude_restore.py <dossier-ou-zip> --mode same-machine`
(réinjecte les secrets) ou `--mode new-environment` (exclut les fichiers d'identité).
Options `--force`, `--yes`, `--target`. Puis suivre `cloud/RESTORE.md` pour le compte.

### Installer le skill
Marketplace : `/plugin marketplace add vdenis06/claude-desktop-backup` puis
`/plugin install desktop-env-backup@vdenis06-tools`. Ou importer
`dist/desktop-env-backup.skill` (Réglages → Capacités → Skills), puis dire
« sauvegarde mon environnement Claude ».

### Planification, limites & sécurité
Planification Windows uniquement pour l'instant (`scripts/Install-Schedule.ps1`) ;
cron/launchd pas encore portés. Jetons OAuth et conversations non exportables.
Énumération complète des Projets via l'app web / export de compte. Description et
instructions d'un Projet re-saisies à la main. `claude_desktop_config.json` peut
contenir des secrets en clair : stockez la sauvegarde dans un endroit sûr.

### Crédits
Auteur : **vdenis06**. Licence MIT. Généré avec l'aide de Claude.
