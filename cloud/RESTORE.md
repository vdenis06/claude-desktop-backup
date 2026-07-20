# Cloud restore runbook / Runbook de restauration cloud

Pairs with the local restore (`python local/claude_restore.py`). The local part
brings back files; this part brings back the account side.

## English

### Case A — same account, new machine
1. Sign in to Claude on the new machine.
2. Run the local restore in **same-machine** mode (reinjects MCP secrets).
3. Reconnect OAuth connectors (from the inventory).
4. Projects, installed plugins and enabled skills come back with the account.
5. Check Python (`uvx`) / Node.js (`npx`) for local MCP servers.

### Case B — new account / new environment
1. Run the local restore in **new-environment** mode (identity files skipped,
   config kept redacted).
2. Reinstall plugins from their marketplaces (the inventory lists them).
3. Reconnect every connector (OAuth) and re-import custom skills.
4. Recreate each Project from its export (`export-project.md`): paste
   name/description/instructions, recreate docs, re-upload files.
5. Re-enter MCP secrets (the config has `__SECRET__` placeholders).
6. Verify against the inventory that nothing is missing.

## Français

À utiliser avec la restauration locale (`python local/claude_restore.py`). Le
local ramène les fichiers ; ceci ramène le côté compte.

### Cas A — même compte, nouvelle machine
1. Se connecter à Claude sur la nouvelle machine.
2. Restauration locale en mode **same-machine** (réinjecte les secrets MCP).
3. Reconnecter les connecteurs OAuth (voir inventaire).
4. Projets, plugins et skills reviennent avec le compte.
5. Vérifier Python (`uvx`) / Node.js (`npx`) pour les serveurs MCP locaux.

### Cas B — nouveau compte / nouvel environnement
1. Restauration locale en mode **new-environment** (fichiers d'identité exclus,
   config gardée caviardée).
2. Réinstaller les plugins depuis leurs marketplaces (listés dans l'inventaire).
3. Reconnecter chaque connecteur (OAuth) et ré-importer les skills perso.
4. Recréer chaque Projet depuis son export (`export-project.md`) : coller
   nom/description/instructions, recréer les docs, ré-uploader les fichiers.
5. Ressaisir les secrets MCP (placeholders `__SECRET__` dans la config).
6. Vérifier avec l'inventaire qu'il ne manque rien.
