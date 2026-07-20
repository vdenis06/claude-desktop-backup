"""Integration tests for local/claude_restore.py.

Uses a synthetic backup in a temp dir and restores to temp targets, so the real
Claude install is never touched.
"""
import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import claude_restore  # noqa: E402
import vault  # noqa: E402


def make_backup(root):
    b = root / "backup"
    b.mkdir()
    cfg = {"mcpServers": {"ha": {"command": "x", "env": {"TOKEN": vault.PLACEHOLDER}}}}
    (b / "claude_desktop_config.json").write_text(json.dumps(cfg), encoding="utf-8")
    (b / "secrets.json").write_text(json.dumps({"ha": {"TOKEN": "realtoken"}}), encoding="utf-8")
    (b / "ant-did").write_text("device-id", encoding="utf-8")
    (b / "Local State").write_text("state", encoding="utf-8")
    (b / "config.json").write_text("{}", encoding="utf-8")
    (b / "MANIFEST.txt").write_text("m", encoding="utf-8")
    ext = b / "Claude Extensions" / "ext1"
    ext.mkdir(parents=True)
    (ext / "f.txt").write_text("x", encoding="utf-8")
    return b


class RestoreTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="claude-restore-test-"))

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_same_machine_reinjects_secrets(self):
        b = make_backup(self.tmp)
        tgt = self.tmp / "t1"
        claude_restore.restore(str(b), target=str(tgt), mode="same-machine", yes=True)
        cfg = json.loads((tgt / "claude_desktop_config.json").read_text(encoding="utf-8"))
        self.assertEqual(cfg["mcpServers"]["ha"]["env"]["TOKEN"], "realtoken")
        self.assertTrue((tgt / "ant-did").exists())
        self.assertTrue((tgt / "Local State").exists())
        self.assertTrue((tgt / "Claude Extensions" / "ext1" / "f.txt").exists())
        self.assertFalse((tgt / "secrets.json").exists())

    def test_new_environment_excludes_identity_and_keeps_placeholder(self):
        b = make_backup(self.tmp)
        tgt = self.tmp / "t2"
        claude_restore.restore(str(b), target=str(tgt), mode="new-environment", yes=True)
        cfg = json.loads((tgt / "claude_desktop_config.json").read_text(encoding="utf-8"))
        self.assertEqual(cfg["mcpServers"]["ha"]["env"]["TOKEN"], vault.PLACEHOLDER)
        self.assertFalse((tgt / "ant-did").exists())
        self.assertFalse((tgt / "Local State").exists())
        self.assertTrue((tgt / "config.json").exists())
        self.assertTrue((tgt / "Claude Extensions" / "ext1" / "f.txt").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
