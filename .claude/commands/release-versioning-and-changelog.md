---
name: release-versioning-and-changelog
description: Workflow command scaffold for release-versioning-and-changelog in claude-desktop-backup.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /release-versioning-and-changelog

Use this workflow when working on **release-versioning-and-changelog** in `claude-desktop-backup`.

## Goal

Prepares a new release by updating version numbers, changelogs, and rebuilding distributable artifacts.

## Common Files

- `VERSION`
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `CHANGELOG.md`
- `README.md`
- `dist/desktop-env-backup.skill`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Update VERSION file
- Update .claude-plugin/plugin.json and/or .claude-plugin/marketplace.json with new version and metadata
- Update CHANGELOG.md with summary of changes
- Update README.md as needed
- Rebuild dist/desktop-env-backup.skill

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.