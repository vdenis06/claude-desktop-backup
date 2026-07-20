"""Tests for local/vault.py — secret isolation round-trips."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import vault  # noqa: E402


def sample():
    return {
        "mcpServers": {
            "ha": {"command": "npx", "args": ["ha-mcp"], "env": {"TOKEN": "abc123", "URL": "http://x"}},
            "fs": {"command": "npx", "args": ["fs"]},
        }
    }


class SplitMergeTests(unittest.TestCase):
    def test_split_extracts_and_placeholders(self):
        redacted, secrets = vault.split_secrets(sample())
        self.assertEqual(secrets, {"ha": {"TOKEN": "abc123", "URL": "http://x"}})
        self.assertEqual(redacted["mcpServers"]["ha"]["env"]["TOKEN"], vault.PLACEHOLDER)

    def test_input_not_mutated(self):
        cfg = sample()
        vault.split_secrets(cfg)
        self.assertEqual(cfg["mcpServers"]["ha"]["env"]["TOKEN"], "abc123")

    def test_roundtrip(self):
        redacted, secrets = vault.split_secrets(sample())
        restored = vault.merge_secrets(redacted, secrets)
        self.assertEqual(restored, sample())

    def test_no_servers_is_safe(self):
        redacted, secrets = vault.split_secrets({"theme": "dark"})
        self.assertEqual(secrets, {})
        self.assertEqual(redacted, {"theme": "dark"})


if __name__ == "__main__":
    unittest.main(verbosity=2)
