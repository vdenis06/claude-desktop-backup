"""Tests for local/paths.py.

Runnable on any host OS: the platform is injected, never taken from the host.
Run: python local/tests/test_paths.py
"""
import os
import sys
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import paths  # noqa: E402

WIN_ENV = {"APPDATA": r"C:\Users\jane\AppData\Roaming", "USERPROFILE": r"C:\Users\jane"}
MAC_ENV = {"HOME": "/Users/jane"}
LINUX_ENV = {"HOME": "/home/jane"}


class ConfigDirTests(unittest.TestCase):
    def test_windows_uses_appdata(self):
        got = paths.config_dir(platform="win32", env=WIN_ENV)
        self.assertEqual(got, Path(WIN_ENV["APPDATA"]) / "Claude")

    def test_windows_without_appdata_falls_back(self):
        got = paths.config_dir(platform="win32", env={"USERPROFILE": r"C:\Users\jane"})
        self.assertEqual(got, Path(r"C:\Users\jane") / "AppData" / "Roaming" / "Claude")

    def test_macos(self):
        got = paths.config_dir(platform="darwin", env=MAC_ENV)
        self.assertEqual(got, Path("/Users/jane") / "Library" / "Application Support" / "Claude")

    def test_linux_default(self):
        got = paths.config_dir(platform="linux", env=LINUX_ENV)
        self.assertEqual(got, Path("/home/jane") / ".config" / "Claude")

    def test_linux_respects_xdg(self):
        env = dict(LINUX_ENV, XDG_CONFIG_HOME="/home/jane/.cfg")
        got = paths.config_dir(platform="linux", env=env)
        self.assertEqual(got, Path("/home/jane/.cfg") / "Claude")

    def test_override_wins(self):
        env = dict(WIN_ENV, CLAUDE_CONFIG_DIR=r"D:\custom\Claude")
        got = paths.config_dir(platform="win32", env=env)
        self.assertEqual(got, Path(r"D:\custom\Claude"))

    def test_unsupported_raises(self):
        with self.assertRaises(paths.UnsupportedPlatformError):
            paths.config_dir(platform="sunos", env={})


class KnownPathsTests(unittest.TestCase):
    def test_desktop_config(self):
        got = paths.desktop_config(platform="darwin", env=MAC_ENV)
        self.assertEqual(got.name, "claude_desktop_config.json")
        self.assertEqual(got.parent, paths.config_dir(platform="darwin", env=MAC_ENV))

    def test_subdirs(self):
        base = paths.config_dir(platform="linux", env=LINUX_ENV)
        self.assertEqual(paths.extensions_dir(platform="linux", env=LINUX_ENV),
                         base / "Claude Extensions")
        self.assertEqual(paths.marketplace_dir(platform="linux", env=LINUX_ENV),
                         base / "MarketPlace")
        self.assertEqual(paths.sessions_dir(platform="linux", env=LINUX_ENV),
                         base / "local-agent-mode-sessions")


if __name__ == "__main__":
    unittest.main(verbosity=2)
