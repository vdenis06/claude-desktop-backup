"""Isolate MCP secrets out of a Claude Desktop config.

A backup must be shareable by default, so the credentials stored in each MCP
server's "env" block are extracted into a separate secrets mapping and the kept
config only retains placeholders. Nothing is hardcoded; input is never mutated.
"""
from __future__ import annotations

import copy

PLACEHOLDER = "__SECRET__"


def split_secrets(config):
    """Return (redacted_config, secrets).

    secrets = {server: {env_key: value, ...}} for every non-empty string value
    under mcpServers[*].env. Those values are replaced by PLACEHOLDER in the
    redacted copy.
    """
    redacted = copy.deepcopy(config)
    secrets = {}
    servers = redacted.get("mcpServers") if isinstance(redacted, dict) else None
    if isinstance(servers, dict):
        for name, spec in servers.items():
            env = spec.get("env") if isinstance(spec, dict) else None
            if not isinstance(env, dict):
                continue
            captured = {k: v for k, v in env.items() if isinstance(v, str) and v != ""}
            for k in captured:
                env[k] = PLACEHOLDER
            if captured:
                secrets[name] = captured
    return redacted, secrets


def merge_secrets(redacted_config, secrets):
    """Return a config with secrets reinjected into mcpServers[*].env."""
    config = copy.deepcopy(redacted_config)
    servers = config.get("mcpServers") if isinstance(config, dict) else None
    if isinstance(servers, dict):
        for name, captured in (secrets or {}).items():
            spec = servers.get(name)
            if isinstance(spec, dict) and isinstance(spec.get("env"), dict):
                spec["env"].update(captured)
    return config
