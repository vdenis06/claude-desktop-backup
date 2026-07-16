# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le
projet respecte le [versionnement sémantique](https://semver.org/lang/fr/).

## [Unreleased]

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

[Unreleased]: https://github.com/vdenis06/claude-desktop-backup/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/vdenis06/claude-desktop-backup/releases/tag/v1.0.0

