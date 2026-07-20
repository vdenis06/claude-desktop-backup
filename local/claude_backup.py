"""Cross-platform backup of the local Claude Desktop environment.

Port of Backup-ClaudeEnv.ps1 to Python (Windows, macOS, Linux). No account- or
machine-specific value is hardcoded. MCP secrets in claude_desktop_config.json
are isolated into secrets.json, which is EXCLUDED from the shareable .zip
(pass --include-secrets to keep them inline).
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import shutil
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import paths  # noqa: E402
import vault  # noqa: E402

ROOT_FILES = [
    "config.json", "Preferences", "Local State", "window-state.json",
    "git-worktrees.json", "plan-usage-history.json", "cowork-enabled-cli-ops.json",
    "extensions-installations.json", "extensions-blocklist.json",
    "buddy-tokens.json", "ant-did",
]
TREES = ["Claude Extensions", "Claude Extensions Settings"]
HARVEST_NAMES = {"metadata.json", "memory.md", "syncs.json", "CLAUDE.md"}
SECRETS_FILE = "secrets.json"


def _log(logfile, msg):
    line = f"{datetime.datetime.now():%H:%M:%S}  {msg}"
    print(line)
    with logfile.open("a", encoding="utf-8") as fh:
        fh.write(line + "\n")


def _copy_tree(src, dst, ignore_paths=None):
    if not src.exists():
        return False
    ignore_paths = ignore_paths or set()

    def _ignore(dirpath, names):
        return [n for n in names if (Path(dirpath) / n) in ignore_paths]

    shutil.copytree(src, dst, ignore=_ignore, dirs_exist_ok=True,
                    ignore_dangling_symlinks=True)
    return True


def _walk_files(root, prune=("node_modules", ".git")):
    """Yield files under root, pruning heavy/irrelevant dirs, tolerant of errors.

    os.walk does not follow symlinks, so Windows reparse points are skipped.
    """
    for dirpath, dirs, files in os.walk(root, onerror=lambda e: None):
        dirs[:] = [d for d in dirs if d not in prune]
        for fn in files:
            yield Path(dirpath) / fn


def _size_bytes(root):
    total = 0
    for f in _walk_files(root):
        try:
            total += f.stat().st_size
        except OSError:
            pass
    return total


def _dir_size_mb(path):
    return round(_size_bytes(path) / (1024 * 1024), 1)


def _big_skill_dirs(src, max_item_mb):
    excluded = set()
    for rel in ("MarketPlace/.agents/skills", "MarketPlace/.claude/skills"):
        parent = src / rel
        if not parent.is_dir():
            continue
        for d in parent.iterdir():
            if d.is_dir():
                if _size_bytes(d) / (1024 * 1024) > max_item_mb:
                    excluded.add(d)
    return excluded


def _backup_configs(src, backup, logfile, include_secrets):
    primary = src / "claude_desktop_config.json"
    secrets_all = {}
    for cfg in sorted(src.glob("claude_desktop_config.json*")):
        dst = backup / cfg.name
        if include_secrets:
            shutil.copy2(cfg, dst)
            _log(logfile, f"  + {cfg.name}")
            continue
        try:
            data = json.loads(cfg.read_text(encoding="utf-8-sig"))
        except (ValueError, OSError):
            _log(logfile, f"  ! {cfg.name} illisible JSON -> ignore (evite fuite secret)")
            continue
        redacted, secrets = vault.split_secrets(data)
        dst.write_text(json.dumps(redacted, indent=2, ensure_ascii=False), encoding="utf-8")
        _log(logfile, f"  + {cfg.name} (secrets retires)")
        if cfg == primary:
            secrets_all = secrets
    if secrets_all and not include_secrets:
        (backup / SECRETS_FILE).write_text(
            json.dumps(secrets_all, indent=2, ensure_ascii=False), encoding="utf-8")
        _log(logfile, f"  + {SECRETS_FILE} (hors .zip)")


def _write_manifest(src, backup_dir, full):
    cfg = backup_dir / "claude_desktop_config.json"
    mcp = []
    if cfg.exists():
        try:
            mcp = list((json.loads(cfg.read_text(encoding="utf-8")).get("mcpServers") or {}).keys())
        except ValueError:
            pass
    lock = src / "MarketPlace" / "skills-lock.json"
    skills = 0
    if lock.exists():
        try:
            skills = len(json.loads(lock.read_text(encoding="utf-8")).get("skills") or {})
        except ValueError:
            pass
    lines = [
        "SAUVEGARDE ENVIRONNEMENT CLAUDE DESKTOP",
        "=======================================",
        f"Date  : {datetime.datetime.now():%Y-%m-%d %H:%M:%S}",
        f"Mode  : {'FULL' if full else 'COEUR'}",
        f"OS    : {sys.platform}",
        "",
        "Serveurs MCP (claude_desktop_config.json) :",
    ]
    lines += [f"  - {m}" for m in mcp] or ["  (aucun)"]
    lines += [
        "",
        f"Skills marketplace (skills-lock.json) : {skills}",
        "",
        "RAPPEL : connecteurs OAuth geres cote claude.ai, a reconnecter.",
        "Secrets MCP isoles dans secrets.json (hors .zip) sauf --include-secrets.",
    ]
    (backup_dir / "MANIFEST.txt").write_text("\n".join(lines), encoding="utf-8")


def _make_zip(backup_dir):
    zip_path = Path(str(backup_dir) + ".zip")
    if zip_path.exists():
        zip_path.unlink()
    secrets_path = backup_dir / SECRETS_FILE
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for f in backup_dir.rglob("*"):
            if f.is_file() and f != secrets_path:
                zf.write(f, f.relative_to(backup_dir))
    return zip_path


def _apply_retention(destination, keep, logfile):
    folders = [p for p in destination.glob("claude-backup-*") if p.is_dir()]
    for old in sorted(folders, key=lambda p: p.stat().st_mtime, reverse=True)[keep:]:
        shutil.rmtree(old, ignore_errors=True)
        _log(logfile, f"  - supprime dossier {old.name}")
    zips = list(destination.glob("claude-backup-*.zip"))
    for old in sorted(zips, key=lambda p: p.stat().st_mtime, reverse=True)[keep:]:
        old.unlink(missing_ok=True)
        _log(logfile, f"  - supprime zip {old.name}")


def backup(destination=None, full=False, max_item_mb=200, no_zip=False,
           keep=10, include_secrets=False):
    src = paths.config_dir()
    if not src.is_dir():
        raise SystemExit(f"Dossier Claude introuvable : {src}")
    home = Path(os.environ.get("USERPROFILE") or os.environ.get("HOME") or Path.home())
    destination = Path(destination) if destination else home / "Claude-Backups"
    stamp = f"{datetime.datetime.now():%Y%m%d-%H%M%S}"
    backup_dir = destination / f"claude-backup-{stamp}"
    backup_dir.mkdir(parents=True, exist_ok=True)
    logfile = backup_dir / "_backup.log"

    _log(logfile, "=== Sauvegarde environnement Claude ===")
    _log(logfile, f"Source      : {src}")
    _log(logfile, f"Destination : {backup_dir}")
    _log(logfile, "Mode        : " + ("FULL" if full else "COEUR"))

    _log(logfile, "--- Config racine ---")
    _backup_configs(src, backup_dir, logfile, include_secrets)
    for name in ROOT_FILES:
        p = src / name
        if p.exists():
            shutil.copy2(p, backup_dir / name)
            _log(logfile, f"  + {name}")

    _log(logfile, "--- Extensions ---")
    for t in TREES:
        if _copy_tree(src / t, backup_dir / t):
            _log(logfile, f"  + {t}")

    _log(logfile, "--- MarketPlace ---")
    mp = src / "MarketPlace"
    if mp.exists():
        ignore = set() if full else _big_skill_dirs(src, max_item_mb)
        _copy_tree(mp, backup_dir / "MarketPlace", ignore)
        _log(logfile, "  + MarketPlace" + ("" if full else f" ({len(ignore)} gros skills exclus > {max_item_mb} Mo)"))

    _log(logfile, "--- Skills perso & projets ---")
    sessions = paths.sessions_dir()
    _copy_tree(sessions / "skills-plugin",
               backup_dir / "local-agent-mode-sessions" / "skills-plugin")
    if sessions.exists():
        harvest = backup_dir / "local-agent-mode-sessions" / "_harvest"
        for f in _walk_files(sessions):
            if f.name in HARVEST_NAMES:
                out = harvest / f.relative_to(sessions)
                out.parent.mkdir(parents=True, exist_ok=True)
                try:
                    shutil.copy2(f, out)
                except OSError:
                    pass
        _log(logfile, "  + _harvest (metadata/memory/syncs/CLAUDE)")
        if full:
            for d in sessions.iterdir():
                if d.is_dir() and d.name != "skills-plugin":
                    _copy_tree(d, backup_dir / "local-agent-mode-sessions" / d.name)

    _write_manifest(src, backup_dir, full)
    _log(logfile, f"Taille dossier : {_dir_size_mb(backup_dir)} Mo")
    if not no_zip:
        _make_zip(backup_dir)
        _log(logfile, f"Archive : {backup_dir}.zip")
    if keep > 0:
        _apply_retention(destination, keep, logfile)
    _log(logfile, "=== Termine ===")
    return backup_dir


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Sauvegarde de l'environnement Claude Desktop (multi-OS).")
    ap.add_argument("--destination")
    ap.add_argument("--full", action="store_true")
    ap.add_argument("--max-item-mb", type=int, default=200)
    ap.add_argument("--no-zip", action="store_true")
    ap.add_argument("--keep", type=int, default=10)
    ap.add_argument("--include-secrets", action="store_true",
                    help="Garder les secrets en clair (deconseille pour un partage).")
    a = ap.parse_args(argv)
    out = backup(a.destination, a.full, a.max_item_mb, a.no_zip, a.keep, a.include_secrets)
    print(f"OK  Sauvegarde : {out}")
    if not a.no_zip:
        print(f"OK  Archive    : {out}.zip")


if __name__ == "__main__":
    main()
