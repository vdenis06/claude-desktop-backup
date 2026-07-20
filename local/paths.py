"""Cross-platform resolution of Claude Desktop paths.

Resolution des chemins de Claude Desktop, multi-plateforme.

No account- or machine-specific value is hardcoded: everything is derived at
runtime from the operating system and the environment. Set CLAUDE_CONFIG_DIR to
override the detected location (useful for tests or non-standard installs).
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

APP_DIR_NAME = "Claude"
ENV_OVERRIDE = "CLAUDE_CONFIG_DIR"


class UnsupportedPlatformError(RuntimeError):
    """Raised when the host OS is not supported."""


def _home(env):
    return Path(env.get("USERPROFILE") or env.get("HOME") or Path.home())


def config_dir(platform=None, env=None):
    """Return the Claude Desktop configuration directory.

    platform: sys.platform-style string ('win32', 'darwin', 'linux');
              defaults to the current host.
    env:      mapping used for environment lookups; defaults to os.environ.
    """
    env = os.environ if env is None else env
    override = env.get(ENV_OVERRIDE)
    if override:
        return Path(override).expanduser()

    plat = platform if platform is not None else sys.platform
    home = _home(env)

    if plat.startswith("win"):
        base = env.get("APPDATA")
        base = Path(base) if base else home / "AppData" / "Roaming"
        return base / APP_DIR_NAME
    if plat == "darwin":
        return home / "Library" / "Application Support" / APP_DIR_NAME
    if plat.startswith("linux"):
        base = env.get("XDG_CONFIG_HOME")
        base = Path(base) if base else home / ".config"
        return base / APP_DIR_NAME

    raise UnsupportedPlatformError(f"Unsupported platform: {plat!r}")


def config_file(name, *, platform=None, env=None):
    """Return the path to a file inside the Claude configuration directory."""
    return config_dir(platform=platform, env=env) / name


def desktop_config(**kw):
    return config_file("claude_desktop_config.json", **kw)


def extensions_dir(**kw):
    return config_dir(**kw) / "Claude Extensions"


def marketplace_dir(**kw):
    return config_dir(**kw) / "MarketPlace"


def sessions_dir(**kw):
    return config_dir(**kw) / "local-agent-mode-sessions"
