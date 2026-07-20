# Enumerate all Projects / Énumérer tous les Projets

The Cowork Projects tool only sees the **attached** Project. To list *every*
Project of an account, drive the web app with **Claude-in-Chrome**. This is the
automated, repeatable procedure.

## English

1. Ensure Claude-in-Chrome is connected (the Chrome extension).
2. Navigate to `https://claude.ai/projects`.
3. Extract the list:
   - `get_page_text` → names, descriptions, last-update dates.
   - `read_page` (filter `interactive`) → each project's link
     `/cowork/project/<id>`.
   - Scroll to the bottom first, so lazy-loaded cards are rendered.
4. Write `projects-manifest.json` next to your backup / inventory: one entry per
   project with `name`, `id`, `url`, `description`, `lastUpdate`.
5. To export a project's content, open its URL and follow `export-project.md`
   (a Cowork session attached to that project reads/writes its docs).

**Read-only.** Never click destructive controls ("delete", "leave", …).

## Français

1. Vérifier que Claude-in-Chrome est connecté (extension Chrome).
2. Aller sur `https://claude.ai/projects`.
3. Extraire la liste :
   - `get_page_text` → noms, descriptions, dates de mise à jour.
   - `read_page` (filtre `interactive`) → le lien de chaque projet
     `/cowork/project/<id>`.
   - Scroller jusqu'en bas d'abord, pour charger les cartes paresseuses.
4. Écrire `projects-manifest.json` à côté de la sauvegarde / l'inventaire : une
   entrée par projet avec `name`, `id`, `url`, `description`, `lastUpdate`.
5. Pour exporter le contenu d'un projet, ouvrir son URL et suivre
   `export-project.md`.

**Lecture seule.** Ne jamais cliquer sur une action destructrice
(« supprimer », « quitter », …).
