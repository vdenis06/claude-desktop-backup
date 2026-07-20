```markdown
# claude-desktop-backup Development Patterns

> Auto-generated skill from repository analysis

## Overview

This skill teaches the core development patterns and workflows for contributing to the `claude-desktop-backup` repository. The project is a Python-based local backup and restore system, designed for cross-platform use (Windows, macOS, Linux), with a focus on conventional commit practices, clear documentation (bilingual EN/FR), and structured release management. You'll learn how to implement features, write tests, document changes, and manage releases in a consistent, maintainable way.

## Coding Conventions

**File Naming:**
- Use `camelCase` for Python files.
  - Example: `backupManager.py`, `fileUtils.py`

**Import Style:**
- Use relative imports within the package.
  - Example:
    ```python
    from .fileUtils import listFiles
    ```

**Export Style:**
- Use named exports (explicitly define what is exported).
  - Example:
    ```python
    def backup():
        pass

    __all__ = ['backup']
    ```

**Commit Messages:**
- Follow [Conventional Commits](https://www.conventionalcommits.org/) with prefixes like `feat`, `docs`, `chore`.
  - Example:
    ```
    feat: add cross-platform restore logic for user settings
    ```

## Workflows

### Feature Implementation with Tests
**Trigger:** When adding or updating a feature in the local backup/restore system  
**Command:** `/new-local-feature`

1. Implement or update Python logic in `local/*.py`.
2. Write or update corresponding tests in `local/tests/test_*.py`.
3. Ensure your code and tests work across Windows, macOS, and Linux.
4. Commit changes using a conventional commit message.

**Example:**
```python
# local/backupManager.py
def backup_user_settings():
    # implementation here
    pass

# local/tests/test_backupManager.py
import unittest
from ..backupManager import backup_user_settings

class TestBackupManager(unittest.TestCase):
    def test_backup_user_settings(self):
        self.assertIsNone(backup_user_settings())
```

---

### Documentation Workflow (Bilingual)
**Trigger:** When adding or updating documentation for features, workflows, or user guides  
**Command:** `/update-docs-bilingual`

1. Create or update markdown files in `cloud/*.md` or `skills/*/SKILL.md`.
2. Ensure all documentation is present in both English and French.
3. Reference new or updated features as needed.
4. Update `README.md` if the changes are user-facing.

**Example:**
```markdown
# Backup Feature / Fonctionnalité de sauvegarde

EN: This feature allows you to back up your desktop environment.

FR: Cette fonctionnalité vous permet de sauvegarder votre environnement de bureau.
```

---

### Release Versioning and Changelog
**Trigger:** When preparing to publish a new release  
**Command:** `/release`

1. Update the `VERSION` file with the new version number.
2. Update `.claude-plugin/plugin.json` and/or `.claude-plugin/marketplace.json` with the new version and metadata.
3. Summarize changes in `CHANGELOG.md`.
4. Update `README.md` as needed.
5. Rebuild the distributable: `dist/desktop-env-backup.skill`.
6. Update `skills/*/SKILL.md` if necessary.
7. Commit with a conventional message (e.g., `chore: release v1.2.0`).

**Example:**
```json
// .claude-plugin/plugin.json
{
  "version": "1.2.0",
  "name": "claude-desktop-backup"
}
```

## Testing Patterns

- **Test Framework:** Not explicitly specified; standard Python `unittest` is commonly used.
- **File Pattern:** Test files are named `test_*.py` and located in `local/tests/`.
- **Structure:** Each test file imports the module under test using relative imports.
- **Example:**
  ```python
  # local/tests/test_fileUtils.py
  import unittest
  from ..fileUtils import listFiles

  class TestFileUtils(unittest.TestCase):
      def test_list_files_empty(self):
          self.assertEqual(listFiles([]), [])
  ```

## Commands

| Command               | Purpose                                               |
|-----------------------|-------------------------------------------------------|
| /new-local-feature    | Start a new feature with associated tests             |
| /update-docs-bilingual| Add or update bilingual documentation                 |
| /release              | Prepare and publish a new release                     |
```