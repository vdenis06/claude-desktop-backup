---
name: documentation-workflow-bilingual
description: Workflow command scaffold for documentation-workflow-bilingual in claude-desktop-backup.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /documentation-workflow-bilingual

Use this workflow when working on **documentation-workflow-bilingual** in `claude-desktop-backup`.

## Goal

Adds or updates bilingual (EN+FR) documentation for cloud or skill usage, including runbooks and user-facing guides.

## Common Files

- `cloud/*.md`
- `skills/*/SKILL.md`
- `README.md`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Create or update markdown files in cloud/*.md or skills/*/SKILL.md
- Ensure content is present in both English and French
- Reference new or updated features as needed

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.