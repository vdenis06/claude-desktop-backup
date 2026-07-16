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
PowerShell fournis dans `scripts/`.

## Prérequis

- **Desktop Commander** disponible (serveur MCP `plugin:desktop-commander`).
  Si ses outils sont différés, les charger via ToolSearch (`query "desktop-commander"`).
- **Windows** + **PowerShell 5.1+** (inclus). Config Claude dans `%APPDATA%\Claude`.

## Ce qui est sauvegardé

Configuration (`claude_desktop_config.json` + ses .bak, `config.json`,
`Preferences`, `Local State`, fichiers d'état), extensions DXT
(`Claude Extensions` + `Settings`), plugins & skills marketplace (`MarketPlace\`),
skills perso (`local-agent-mode-sessions\skills-plugin`) et les
`metadata.json` / `memory.md` / `syncs.json` des projets. Les caches
régénérables (VM, Cache, GPUCache, logs…) sont exclus. Mode « cœur » ≈ 80 Mo.

## Procédure — SAUVEGARDE

1. Charger Desktop Commander si nécessaire.
2. Déposer les scripts sur la machine : depuis le dossier `scripts/` de ce skill,
   copier `Backup-ClaudeEnv.ps1` (et `Install-Schedule.ps1`) via Desktop
   Commander dans `%USERPROFILE%\Claude-Tools\`. Déterminer `%USERPROFILE%`
   avec `$env:USERPROFILE` (ne jamais coder un nom d'utilisateur en dur).
3. Lancer via Desktop Commander `start_process` (timeout ≥ 180000 ms, la
   compression du .zip peut être longue) :

   ```
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Claude-Tools\Backup-ClaudeEnv.ps1"
   ```

   Options : `-Full` (tout inclure), `-Destination "D:\..."`, `-Keep 10`.
4. La compression peut dépasser le timeout de l'outil : ne pas conclure à un
   échec. Vérifier en lisant `_backup.log` dans le dossier créé et la taille du
   `.zip`.
5. Rapporter le chemin du dossier et de l'archive.

## Procédure — RESTAURATION

1. **Claude Desktop doit être fermé** (option `-Force` pour le fermer).
2. Déposer `scripts/Restore-ClaudeEnv.ps1` dans `%USERPROFILE%\Claude-Tools\`.
3. Lancer :

   ```
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Claude-Tools\Restore-ClaudeEnv.ps1" -Source "<dossier ou .zip>"
   ```

   `-Yes` évite la confirmation, `-Force` ferme Claude. La config actuelle est
   sauvegardée avant écrasement.
4. Rappeler les étapes post‑restauration : reconnecter les **connecteurs OAuth**
   (non restaurables) via Réglages → Connecteurs ; vérifier Python (`uvx`) /
   Node.js (`npx`) pour les serveurs MCP locaux.

## Procédure — PLANIFICATION

Pour une sauvegarde automatique récurrente :

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Claude-Tools\Install-Schedule.ps1" -Day Friday -Time 12:00 -Keep 10
```

Supprimer : ajouter `-Remove`.

## ⚠️ Sécurité

`claude_desktop_config.json` peut contenir des **secrets en clair** (tokens,
mots de passe des serveurs MCP). La sauvegarde les inclut. Prévenir
l'utilisateur de stocker le dossier / .zip dans un endroit chiffré et de ne pas
le partager.

## Notes

- Les **connecteurs OAuth** et les **projets/conversations cloud** vivent côté
  claude.ai : non présents dans les fichiers locaux, ils reviennent en se
  reconnectant au compte.
- `MarketPlace\skills-lock.json` liste les sources des skills marketplace : il
  suffit pour les réinstaller.

<!-- version: 1.0.0 -->

