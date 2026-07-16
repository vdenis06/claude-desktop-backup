# Claude Desktop Backup (Windows)

![Platform](https://img.shields.io/badge/platform-Windows-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.0.0-brightgreen)

Sauvegardez et restaurez toute la **configuration et la personnalisation** de
Claude Desktop sur Windows : serveurs MCP, extensions, plugins, skills
marketplace, skills perso et paramétrage local des projets. Disponible en
**scripts PowerShell** et en **skill Claude** installable.

> 100 % local — rien n'est envoyé sur le réseau.

---

## Fonctionnalités

- Sauvegarde datée + archive `.zip`, avec **rétention** configurable.
- Mode **cœur** (~80 Mo) ou **`-Full`** (tout inclus).
- Exclusion automatique des caches régénérables (VM, GPUCache, logs…).
- **Restauration** avec sauvegarde de sécurité préalable de l'existant.
- **Planification** Windows (tâche hebdomadaire, sans droits admin).
- **Skill Claude** pour lancer la sauvegarde depuis une conversation.

---

## Structure du dépôt

```
claude-desktop-backup/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTING.md
├── .gitignore
├── scripts/
│   ├── Backup-ClaudeEnv.ps1      # sauvegarde (config, extensions, plugins, skills)
│   ├── Restore-ClaudeEnv.ps1     # restauration depuis un dossier ou un .zip
│   └── Install-Schedule.ps1      # tâche planifiée (création/suppression)
├── skill/
│   └── SKILL.md                  # définition du skill Claude
├── tools/
│   └── Build-Skill.ps1           # assemble dist/desktop-env-backup.skill
└── dist/
    └── desktop-env-backup.skill  # skill prêt à installer
```

---

## Prérequis

- **Windows 10/11**, **PowerShell 5.1+** (préinstallé).
- Aucun droit administrateur. Les commandes utilisent `-ExecutionPolicy Bypass`
  (pas de modification permanente de la politique).
- Pour restaurer certains **serveurs MCP locaux** : leurs runtimes (souvent
  **Python** via `uvx`, **Node.js** via `npx`).
- **Uniquement pour le skill** : le connecteur **Desktop Commander** dans Claude.

> macOS/Linux non couverts (config macOS : `~/Library/Application Support/Claude`).

---

## Démarrage rapide

```powershell
git clone https://github.com/vdenis06/claude-desktop-backup.git
cd claude-desktop-backup

# Sauvegarde "cœur" (config + personnalisation) + .zip
powershell -ExecutionPolicy Bypass -File .\scripts\Backup-ClaudeEnv.ps1
```

Sauvegarde créée dans `%USERPROFILE%\Claude-Backups\claude-backup-<date>\`.

### Options

| Option | Effet |
|---|---|
| `-Full` | Inclut les skills volumineux et l'historique complet des sessions. |
| `-Destination "D:\Backups"` | Change le dossier de destination. |
| `-Keep 10` | Sauvegardes à conserver (défaut 10 ; `0` = illimité). |
| `-MaxItemMB 200` | Seuil d'exclusion des gros skills en mode cœur. |
| `-NoZip` | Ne crée pas l'archive. |

---

## Planification automatique

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Install-Schedule.ps1 -Day Friday -Time 12:00 -Keep 10
# Supprimer :
powershell -ExecutionPolicy Bypass -File .\scripts\Install-Schedule.ps1 -Remove
```

Tâche hebdomadaire, option *StartWhenAvailable* (rattrape une exécution manquée).
S'exécute lorsque l'utilisateur est connecté à Windows.

---

## Restauration

Fermez Claude Desktop, puis :

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Restore-ClaudeEnv.ps1 -Source "D:\Backups\claude-backup-<date>.zip"
```

`-Force` ferme Claude s'il est ouvert, `-Yes` enchaîne sans confirmation.
Après restauration : reconnectez votre compte et les **connecteurs OAuth**
(non restaurables), vérifiez Python/Node.js pour vos serveurs MCP locaux.

---

## Installer le skill Claude

1. Installez et connectez **Desktop Commander** dans Claude Desktop.
2. Importez `dist/desktop-env-backup.skill` via **Réglages → Capacités → Skills**.
3. Dites par ex. « **sauvegarde mon environnement Claude** ».

---

## Sécurité

`claude_desktop_config.json` peut contenir des **secrets en clair** (tokens, mots
de passe des serveurs MCP). La sauvegarde les inclut : stockez le dossier / `.zip`
dans un endroit **chiffré** et ne le partagez pas. En cas de fuite, révoquez puis
régénérez les secrets.

---

## Développement — (re)construire le skill

Après modification de `skill/SKILL.md` ou des scripts :

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\Build-Skill.ps1
```

Le script assemble `SKILL.md` + `scripts/*.ps1` dans une archive à séparateurs
`/` (requis par l'installeur) et produit `dist/desktop-env-backup.skill`.

---

## Limites

- Windows uniquement.
- Connecteurs OAuth non restaurables (jetons côté serveur).
- Projets et conversations stockés côté claude.ai (reviennent en se reconnectant).

---

## Contribuer

Voir [CONTRIBUTING.md](CONTRIBUTING.md). Les PR sont bienvenues.

## Licence

MIT — voir [LICENSE](LICENSE).

## Crédits

Auteur : **vdenis06** — https://github.com/vdenis06

Ce projet a été **généré entièrement avec l'aide de Claude** (Anthropic).


