---
name: desktop-env-backup
description: >-
  Sauvegarde et restauration de l'environnement Claude Desktop (Windows) via
  Desktop Commander. Utiliser quand l'utilisateur dit « sauvegarde mon
  environnement Claude », « backup Claude », « sauvegarde ma config Claude »,
  « sauvegarde complète de Claude Desktop », « restaure mon environnement
  Claude », « restaure ma config Claude », ou avant une réinstallation / mise à
  jour risquée de Claude Desktop. Copie config, serveurs MCP, extensions DXT,
  plugins & skills marketplace et skills perso vers un dossier daté + archive
  .zip (avec rétention), et restaure depuis une sauvegarde.
---

# desktop-env-backup — Sauvegarde / restauration de Claude Desktop

Automatise la sauvegarde et la restauration de l'environnement Claude Desktop
sur **Windows**, via **Desktop Commander** (MCP local) qui exécute les scripts
PowerShell fournis.

## Prérequis

- **Desktop Commander** disponible (serveur MCP `plugin:desktop-commander`).
  Si ses outils sont différés, les charger via ToolSearch (`query "desktop-commander"`).
- **Windows** + **PowerShell 5.1+** (inclus). Config Claude dans `%APPDATA%\Claude`.

## Où sont les scripts

- Installé comme **plugin Claude Code / marketplace** : à `${CLAUDE_PLUGIN_ROOT}/scripts/`.
- Installé comme **fichier .skill** : dans le dossier `scripts/` de ce skill.

## Ce qui est sauvegardé

Configuration (`claude_desktop_config.json` + ses .bak, `config.json`,
`Preferences`, `Local State`, fichiers d'état), extensions DXT
(`Claude Extensions` + `Settings`), plugins & skills marketplace (`MarketPlace\`),
skills perso (`local-agent-mode-sessions\skills-plugin`) et les
`metadata.json` / `memory.md` / `syncs.json` des projets. Les caches
régénérables (VM, Cache, GPUCache, logs…) sont exclus. Mode « cœur » ≈ 80 Mo.

## Procédure — SAUVEGARDE

1. Charger Desktop Commander si nécessaire.
2. Déposer les scripts sur la machine : copier `Backup-ClaudeEnv.ps1` (et
   `Install-Schedule.ps1`) via Desktop Commander dans `%USERPROFILE%\Claude-Tools\`.
   Déterminer `%USERPROFILE%` avec `$env:USERPROFILE` (jamais de nom d'utilisateur en dur).
3. Lancer via Desktop Commander `start_process` (timeout ≥ 180000 ms) :

   ```
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Claude-Tools\Backup-ClaudeEnv.ps1"
   ```

   Options : `-Full`, `-Destination "D:\..."`, `-Keep 10`.
4. La compression peut dépasser le timeout : vérifier `_backup.log` et le `.zip`.
5. Rapporter le chemin du dossier et de l'archive.

## Procédure — RESTAURATION

1. **Claude Desktop doit être fermé** (option `-Force` pour le fermer).
2. Déposer `Restore-ClaudeEnv.ps1` dans `%USERPROFILE%\Claude-Tools\`.
3. Lancer :

   ```
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Claude-Tools\Restore-ClaudeEnv.ps1" -Source "<dossier ou .zip>"
   ```

   `-Yes` évite la confirmation, `-Force` ferme Claude.
4. Rappeler : reconnecter les **connecteurs OAuth** (non restaurables) ; vérifier
   Python (`uvx`) / Node.js (`npx`) pour les serveurs MCP locaux.

## Procédure — PLANIFICATION

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Claude-Tools\Install-Schedule.ps1" -Day Friday -Time 12:00 -Keep 10
```

Supprimer : ajouter `-Remove`.

## ⚠️ Sécurité

`claude_desktop_config.json` peut contenir des **secrets en clair** (tokens,
mots de passe MCP). La sauvegarde les inclut. Prévenir l'utilisateur de stocker
le dossier / .zip dans un endroit chiffré et de ne pas le partager.

<!-- version: 1.0.0 -->
