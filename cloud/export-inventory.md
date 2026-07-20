# Export the account-side inventory / Exporter l'inventaire du compte

The local backup (`local/`) captures files on disk. It cannot see the account
side of Claude: installed plugins, connectors, enabled skills and Projects live
on the server. This runbook captures that half as a manifest so the environment
can be rebuilt on any machine or account. Nothing here is account-specific — it
discovers whatever exists.

## English

Run from a **Cowork session** (Claude desktop app), which can call the account
tools.

1. List installed plugins (`ListPlugins`), connectors (`ListConnectors`) and
   enabled skills (`ListSkills`).
2. Read the attached Project (`project_info`): name, description, custom
   instructions, docs, knowledge size.
3. Write two files next to your backup:
   - `manifest-cloud.json` — machine-readable inventory (plugins; connectors
     with their OAuth flag; skills split builtin/custom; attached project).
   - `INVENTORY.md` — human-readable version + rebuild notes.
4. Store them with the local backup so a restore has both halves.

### Limitation — listing every Project
The Cowork Projects tool only sees the **attached** Project. To capture *all*
Projects: use the web app (claude.ai → Projects) then export each (see
`export-project.md`), the account data export (Settings → Privacy/Account), or a
Claude-in-Chrome pass over the Projects list. OAuth tokens and conversation
history are never exportable — reconnect / re-auth.

## Français

À lancer depuis une **session Cowork** (app Claude), qui peut appeler les outils
de compte.

1. Lister les plugins (`ListPlugins`), connecteurs (`ListConnectors`) et skills
   activés (`ListSkills`).
2. Lire le Projet attaché (`project_info`) : nom, description, instructions,
   docs, taille des connaissances.
3. Écrire deux fichiers à côté de la sauvegarde :
   - `manifest-cloud.json` — inventaire exploitable (plugins ; connecteurs avec
     leur drapeau OAuth ; skills intégrés/perso ; projet attaché).
   - `INVENTORY.md` — version lisible + notes de reconstruction.
4. Les ranger avec la sauvegarde locale pour disposer des deux moitiés.

### Limite — lister tous les Projets
L'outil Projects de Cowork ne voit que le Projet **attaché**. Pour capturer
*tous* les Projets : l'app web (claude.ai → Projects) puis export de chacun
(voir `export-project.md`), l'export de compte (Réglages → Confidentialité), ou
une passe Claude-in-Chrome. Les jetons OAuth et l'historique ne sont jamais
exportables — reconnecter / ré-authentifier.
