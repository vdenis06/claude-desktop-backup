---
name: desktop-env-backup
description: >-
  Back up and restore the local Claude Desktop environment (Windows, macOS,
  Linux) via Desktop Commander. Sauvegarde et restauration de l'environnement
  Claude Desktop. Use when the user says "back up my Claude environment",
  "backup Claude", "restore my Claude config", « sauvegarde mon environnement
  Claude », « restaure ma config Claude », or before a risky reinstall/update.
  Copies config, MCP servers, DXT extensions, marketplace plugins & skills and
  personal skills to a dated folder + .zip; MCP secrets are isolated out of the
  shareable zip. Restores same-machine or into a new environment.
---

# desktop-env-backup — Backup / restore Claude Desktop (multi-OS)

Cross-platform backup and restore of the local Claude Desktop environment, run
through **Desktop Commander** (local MCP) which executes the Python scripts.

## Prerequisites / Prérequis
- **Desktop Commander** available (MCP `plugin:desktop-commander`). If its tools
  are deferred, load them via ToolSearch (`query "desktop-commander"`).
- **Python 3.8+** on PATH. Config auto-detected per OS (Windows
  `%APPDATA%\Claude`, macOS `~/Library/Application Support/Claude`, Linux
  `~/.config/Claude`); override with `CLAUDE_CONFIG_DIR`.

## Where the scripts are
- Installed as a **plugin**: `${CLAUDE_PLUGIN_ROOT}/local/`.
- Installed as a **.skill file**: the `local/` folder of this skill.

## What is backed up
Config (`claude_desktop_config.json` + variants, `config.json`, `Preferences`,
`Local State`, state files), DXT extensions, marketplace plugins & skills
(`MarketPlace/`), personal skills (`local-agent-mode-sessions/skills-plugin`)
and project shadows (`metadata.json`/`memory.md`/`syncs.json`/`CLAUDE.md`).
Regenerable caches are skipped. **MCP secrets** are moved to `secrets.json`,
excluded from the `.zip` by default.

## Procedure — BACKUP
1. Load Desktop Commander if needed.
2. Copy the `local/` scripts onto the machine, e.g. into `Claude-Tools/`. Never
   hardcode a username (use the OS home/env).
3. Run (start_process, timeout >= 180000 ms):
   `python <path>/claude_backup.py [--full] [--destination DIR] [--keep 10]`
4. Zipping large environments is slow; check `_backup.log` and the `.zip`.
5. Report the folder and archive paths.

## Procedure — RESTORE
1. **Close Claude Desktop** (the script refuses if it is open; `--force`).
2. Same machine:
   `python <path>/claude_restore.py <folder-or-zip> --mode same-machine`
   (reinjects secrets from `secrets.json`).
3. New environment / new account:
   `python <path>/claude_restore.py <folder-or-zip> --mode new-environment`
   then follow `cloud/RESTORE.md` to rebuild the account side.
4. Reconnect OAuth connectors; check Python (`uvx`) / Node (`npx`) for MCP.

## Account side (Projects, plugins, connectors)
The scripts cover local files only. For the account half, follow the bilingual
runbooks: `cloud/export-inventory.md`, `cloud/export-project.md`,
`cloud/RESTORE.md`.

## Scheduling
Windows only for now via `scripts/Install-Schedule.ps1` (weekly task, no admin).
Cross-platform scheduling (cron/launchd) is not yet ported.

## ⚠️ Security / Sécurité
`claude_desktop_config.json` may contain plaintext MCP secrets. By default they
are isolated into `secrets.json`, kept out of the `.zip`. The `.zip` is
shareable; the backup folder (with secrets) is not — store it safely.

## Procédure (FR, résumé)
Sauvegarde : `python .../claude_backup.py` (`--full`, `--destination`,
`--keep`). Restauration : `--mode same-machine` (réinjecte les secrets) ou
`--mode new-environment` (exclut les fichiers d'identité, puis suivre
`cloud/RESTORE.md`). Fermer Claude avant de restaurer ; reconnecter les
connecteurs OAuth.

<!-- version: 1.0.0 -->
