---
name: feature-implementation-with-tests
description: Workflow command scaffold for feature-implementation-with-tests in claude-desktop-backup.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /feature-implementation-with-tests

Use this workflow when working on **feature-implementation-with-tests** in `claude-desktop-backup`.

## Goal

Implements a new feature in the local Python codebase, with associated tests to ensure correctness across platforms.

## Common Files

- `local/*.py`
- `local/tests/test_*.py`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Implement or update Python logic in local/*.py
- Write or update corresponding tests in local/tests/test_*.py
- Verify multi-platform support (Windows/macOS/Linux) in implementation and tests

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.