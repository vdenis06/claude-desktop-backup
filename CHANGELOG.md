# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le
projet respecte le [versionnement sémantique](https://semver.org/lang/fr/).

## [2.0.0] - 2026-07-20
### Ajouté / Added
- Portage **multi-plateforme** (Windows, macOS, Linux) en Python : `local/paths.py`, `local/claude_backup.py`, `local/claude_restore.py`, `local/vault.py`.
- **Isolation des secrets** MCP dans `secrets.json`, exclu du `.zip` partageable (`--include-secrets` pour l'ancien comportement).
- **Restauration à deux voies** : `--mode same-machine` (réinjecte les secrets) et `--mode new-environment` (exclut les fichiers d'identité).
- Module **`cloud/`** : runbooks bilingues (inventaire du compte, export intégral d'un Projet, restauration cas A/B).
- Skill bilingue EN+FR pointant sur les scripts Python ; CI en matrice 3 OS ; 15 tests.
- Support marketplace Claude Code (`.claude-plugin/`).
### Modifié / Changed
- README unique bilingue (EN+FR).
- Le skill utilise désormais les scripts Python (`local/`).
### Déprécié / Deprecated
- Scripts PowerShell `scripts/Backup-ClaudeEnv.ps1` / `Restore-ClaudeEnv.ps1` conservés pour Windows mais remplacés par les scripts Python.

## [1.0.0] - 2026-07-16

### Ajouté
- `Backup-ClaudeEnv.ps1` : sauvegarde datée (config, extensions DXT, plugins &
  skills marketplace, skills perso, métadonnées de projets) + archive `.zip`.
- Mode « cœur » (léger) et `-Full` (complet) ; exclusion des caches régénérables.
- Exclusion des skills volumineux basée sur la taille (`-MaxItemMB`).
- Rétention configurable (`-Keep`, défaut 10).
- `Restore-ClaudeEnv.ps1` : restauration depuis un dossier ou un `.zip`, avec
  sauvegarde de sécurité préalable de la configuration existante.
- `Install-Schedule.ps1` : tâche planifiée Windows (création/suppression),
  paramétrable (jour, heure, rétention), sans droits administrateur.
- Skill Claude `desktop-env-backup` (SKILL.md + scripts) et `tools/Build-Skill.ps1`.
- Documentation : README, prérequis, guide d'installation, note de sécurité.

[2.0.0]: https://github.com/vdenis06/claude-desktop-backup/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/vdenis06/claude-desktop-backup/releases/tag/v1.0.0


