"""Cross-platform restore of the local Claude Desktop environment.

Two modes:
  same-machine     reinjects secrets from secrets.json and restores everything.
  new-environment  skips identity files (ant-did, buddy-tokens.json, Local
                   State), keeps the redacted config, and points to the cloud
                   runbook for the account-side rebuild.

No account- or machine-specific value is hardcoded.
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import paths  # noqa: E402
import vault  # noqa: E402

SKIP_FILES = {"MANIFEST.txt", "_backup.log", "secrets.json"}
IDENTITY_FILES = {"ant-did", "buddy-tokens.json", "Local State"}
TREES = ["Claude Extensions", "Claude Extensions Settings", "MarketPlace"]


def _prepare_source(source):
    src = Path(source)
    if not src.exists():
        raise SystemExit(f"Source introuvable : {src}")
    if src.suffix.lower() == ".zip":
        tmp = Path(tempfile.mkdtemp(prefix="claude-restore-"))
        with zipfile.ZipFile(src) as zf:
            zf.extractall(tmp)
        return tmp, tmp
    return src, None


def _claude_running():
    try:
        if sys.platform.startswith("win"):
            out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq Claude.exe"],
                                 capture_output=True, text=True, timeout=10).stdout
            return "Claude.exe" in out
        rc = subprocess.run(["pgrep", "-x", "Claude"],
                            capture_output=True, text=True, timeout=10).returncode
        return rc == 0
    except Exception:
        return None


def _copy_tree(src, dst):
    if not src.exists():
        return False
    shutil.copytree(src, dst, dirs_exist_ok=True, ignore_dangling_symlinks=True)
    return True


def _safety_backup(target):
    home = Path(os.environ.get("USERPROFILE") or os.environ.get("HOME") or Path.home())
    safe = home / "Claude-Backups" / f"_avant-restauration-{datetime.datetime.now():%Y%m%d-%H%M%S}"
    safe.mkdir(parents=True, exist_ok=True)
    candidates = list(target.glob("claude_desktop_config.json*"))
    candidates += [target / n for n in ("config.json", "Preferences", "Local State")]
    for f in candidates:
        if f.exists():
            shutil.copy2(f, safe / f.name)
    return safe


def _restore_configs(backup, target, mode, log):
    primary = backup / "claude_desktop_config.json"
    secrets_file = backup / "secrets.json"
    reinject = mode == "same-machine" and secrets_file.exists() and primary.exists()
    for f in sorted(backup.glob("claude_desktop_config.json*")):
        if f == primary and reinject:
            cfg = json.loads(primary.read_text(encoding="utf-8"))
            secrets = json.loads(secrets_file.read_text(encoding="utf-8"))
            merged = vault.merge_secrets(cfg, secrets)
            (target / f.name).write_text(
                json.dumps(merged, indent=2, ensure_ascii=False), encoding="utf-8")
            log(f"  + {f.name} (secrets reinjectes)")
        else:
            shutil.copy2(f, target / f.name)
            log(f"  + {f.name}")
    if mode == "same-machine" and primary.exists() and not secrets_file.exists():
        log("  ! pas de secrets.json (restauration depuis .zip ?) : config avec placeholders")


def restore(source, target=None, mode="same-machine", yes=False, force=False):
    if mode not in ("same-machine", "new-environment"):
        raise SystemExit(f"Mode inconnu : {mode}")
    live = target is None
    target_dir = paths.config_dir() if live else Path(target)
    backup, tmp = _prepare_source(source)

    def log(m):
        print(m)

    if not (backup / "MANIFEST.txt").exists():
        print("Attention : MANIFEST.txt absent — est-ce bien une sauvegarde Claude ?")

    if live:
        running = _claude_running()
        if running and not force:
            if tmp:
                shutil.rmtree(tmp, ignore_errors=True)
            raise SystemExit("Claude Desktop est ouvert. Fermez-le (ou utilisez --force).")
        if not yes:
            r = input(f"Restaurer {backup} -> {target_dir} en mode {mode} ? (oui/non) ")
            if r.strip().lower() not in ("oui", "o", "yes", "y"):
                print("Annule.")
                if tmp:
                    shutil.rmtree(tmp, ignore_errors=True)
                return None
        print(f"Config actuelle sauvegardee : {_safety_backup(target_dir)}")

    target_dir.mkdir(parents=True, exist_ok=True)
    print(f"=== Restauration ({mode}) -> {target_dir} ===")
    _restore_configs(backup, target_dir, mode, log)

    for f in backup.iterdir():
        if not f.is_file() or f.name.startswith("claude_desktop_config.json"):
            continue
        if f.name in SKIP_FILES:
            continue
        if mode == "new-environment" and f.name in IDENTITY_FILES:
            log(f"  ~ {f.name} (ignore en new-environment)")
            continue
        shutil.copy2(f, target_dir / f.name)
        log(f"  + {f.name}")

    for t in TREES:
        if _copy_tree(backup / t, target_dir / t):
            log(f"  + {t}")
    sessions = backup / "local-agent-mode-sessions"
    if sessions.exists():
        for d in sessions.iterdir():
            if d.is_dir() and d.name != "_harvest":
                _copy_tree(d, target_dir / "local-agent-mode-sessions" / d.name)
        log("  + local-agent-mode-sessions")

    if tmp:
        shutil.rmtree(tmp, ignore_errors=True)
    _print_next_steps(mode)
    return target_dir


def _print_next_steps(mode):
    print("")
    print("ETAPES SUIVANTES :")
    print("  1. Relancez Claude Desktop.")
    print("  2. Reconnectez les connecteurs OAuth (Gmail, Drive, M365...).")
    print("  3. Verifiez Python (uvx) / Node.js (npx) pour vos serveurs MCP locaux.")
    if mode == "new-environment":
        print("  4. Deroulez le runbook cloud (cloud/RESTORE.md) : recreez les")
        print("     projets, re-uploadez les connaissances, reinstallez les plugins.")
        print("  5. Ressaisissez les secrets MCP (valeurs __SECRET__ dans la config).")


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Restauration de l'environnement Claude Desktop (multi-OS).")
    ap.add_argument("source", help="Dossier de sauvegarde ou archive .zip")
    ap.add_argument("--target", help="Cible (defaut: dossier Claude detecte). Utile pour tester.")
    ap.add_argument("--mode", choices=["same-machine", "new-environment"], default="same-machine")
    ap.add_argument("--yes", action="store_true")
    ap.add_argument("--force", action="store_true", help="Ignore la detection de Claude ouvert.")
    a = ap.parse_args(argv)
    restore(a.source, a.target, a.mode, a.yes, a.force)


if __name__ == "__main__":
    main()
