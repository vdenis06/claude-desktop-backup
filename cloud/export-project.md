# Export one Project integrally / Exporter un Projet intégralement

## English

A Project is server-side: name, description, custom instructions, knowledge
(text docs), file uploads, sync sources. Export layout:

```
project-<slug>-<date>/
  project.json     # name, description, instructions, sync sources, index
  docs/            # one file per text doc
  files/           # downloadable uploads (PDFs...); binaries listed in json
```

Steps (Cowork session **attached to the Project**):

1. `project_info` → write `project.json` (name, description, instructions, sync
   sources, list of docs + files with sizes).
2. For each text doc: `project_read` → `docs/<name>`.
3. For each readable upload: save into `files/`; list non-downloadable ones in
   `project.json` as "re-upload manually".

Restore:

- **Same account / new machine** — Projects come back on sign-in; this export is
  insurance and a reference.
- **New account / clone into a new Project** — create a Project, paste name +
  description + instructions **manually** (the tool cannot write those fields),
  then a Cowork session attached to the new Project recreates `docs/` via
  `project_write` (automatic). Re-upload `files/`, reconnect sync sources, and
  make sure required connectors/skills exist (see the inventory).

## Français

Un Projet est côté serveur : nom, description, instructions, connaissances (docs
texte), fichiers uploadés, sources de sync. Format d'export :

```
project-<slug>-<date>/
  project.json     # nom, description, instructions, sources de sync, index
  docs/            # un fichier par doc texte
  files/           # uploads récupérables (PDF...) ; binaires listés dans json
```

Étapes (session Cowork **attachée au Projet**) :

1. `project_info` → écrire `project.json`.
2. Chaque doc texte : `project_read` → `docs/<nom>`.
3. Chaque upload lisible : dans `files/` ; lister les non récupérables dans
   `project.json` (« à ré-uploader »).

Restauration :

- **Même compte / nouvelle machine** — les Projets reviennent à la connexion ;
  cet export est une assurance et une référence.
- **Nouveau compte / clone** — créer un Projet, coller nom + description +
  instructions **à la main** (l'outil n'écrit pas ces champs), puis une session
  Cowork attachée recrée `docs/` via `project_write` (auto). Ré-uploader
  `files/`, reconnecter les sources de sync, vérifier connecteurs/skills (voir
  l'inventaire).
