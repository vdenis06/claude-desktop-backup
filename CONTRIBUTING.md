# Contribuer

Merci de votre intérêt ! Ce projet cible **Windows / PowerShell**.

## Signaler un bug ou proposer une amélioration

Ouvrez une *issue* en précisant : version de Windows, version de PowerShell
(`$PSVersionTable.PSVersion`), la commande lancée et le message d'erreur complet.

## Proposer du code (Pull Request)

1. Forkez le dépôt et créez une branche : `git checkout -b feat/ma-fonction`.
2. Respectez le style existant (commentaires en tête de script, paramètres
   documentés, pas de chemin utilisateur codé en dur — utilisez `$env:USERPROFILE`
   / `$env:APPDATA`).
3. Ne committez **aucune donnée personnelle** (chemins, tokens, noms de machine).
4. Si vous modifiez `skill/SKILL.md` ou les scripts, régénérez le skill :
   `powershell -ExecutionPolicy Bypass -File .\tools\Build-Skill.ps1`.
5. Mettez à jour le `CHANGELOG.md`.
6. Testez la sauvegarde ET la restauration sur une machine réelle avant la PR.

## Sécurité

Ne publiez jamais de sauvegarde réelle : `claude_desktop_config.json` contient
des secrets. Pour signaler une faille, ouvrez une issue *sans* données sensibles.
