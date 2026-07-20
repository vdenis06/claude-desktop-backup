"""Regression tests for local/claude_backup.py.

Covers two fixes:
- _make_zip must exclude ONLY the top-level secrets.json, not nested ones.
- _backup_configs must tolerate a UTF-8 BOM in a config (not silently skip it).
"""
import json
import os
import shutil
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import claude_backup  # noqa: E402
import vault  # noqa: E402


class MakeZipTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="claude-backup-test-"))

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_zip_excludes_only_toplevel_secrets(self):
        b = self.tmp / "claude-backup-x"
        (b / "sub").mkdir(parents=True)
        (b / "secrets.json").write_text("{}", encoding="utf-8")          # top-level -> excluded
        (b / "sub" / "secrets.json").write_text("{}", encoding="utf-8")  # nested -> kept
        (b / "config.json").write_text("{}", encoding="utf-8")
        zip_path = claude_backup._make_zip(b)
        names = [n.replace("\\", "/") for n in zipfile.ZipFile(zip_path).namelist()]
        self.assertNotIn("secrets.json", names)
        self.assertIn("sub/secrets.json", names)
        self.assertIn("config.json", names)


class BomConfigTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="claude-backup-bom-"))

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_config_with_bom_is_backed_up(self):
        src = self.tmp / "src"
        src.mkdir()
        backup = self.tmp / "bak"
        backup.mkdir()
        cfg = {"mcpServers": {"ha": {"env": {"TOKEN": "abc123"}}}}
        # Write WITH a UTF-8 BOM (utf-8-sig) — must still be parsed, not skipped.
        (src / "claude_desktop_config.json").write_text(json.dumps(cfg), encoding="utf-8-sig")
        claude_backup._backup_configs(src, backup, self.tmp / "log.txt", include_secrets=False)
        restored = backup / "claude_desktop_config.json"
        self.assertTrue(restored.exists(), "config with BOM was skipped")
        out = json.loads(restored.read_text(encoding="utf-8"))
        self.assertEqual(out["mcpServers"]["ha"]["env"]["TOKEN"], vault.PLACEHOLDER)
        self.assertTrue((backup / "secrets.json").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
