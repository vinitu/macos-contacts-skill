# AGENTS.md

## Purpose

This repository provides an AI skill for managing macOS Contacts.app through AppleScript.

Primary goals:
- keep the CLI dependency-free (bash + osascript only);
- preserve predictable JSON I/O for agents;
- read-only by default; write operations (add, edit, delete) must be explicit commands.

## Repository Layout

- `SKILL.md`: the skill contract and usage instructions for agents.
- `README.md`: public project overview and installation notes.
- `.github/workflows/ci-pr.yml`: PR validation, auto-merge, version bump, tag, and release flow.
- `.github/workflows/ci-main.yml`: main-branch validation, patch tag, and release flow.
- `scripts/contacts.sh`: main CLI script — all Contacts operations.

## Working Rules

- The CLI must work with bash and osascript only. No external dependencies.
- Preserve CLI behavior. Existing commands, arguments, and output shapes should remain stable unless the task explicitly requires a breaking change.
- Preserve JSON output as the integration boundary. Success and error responses should stay machine-readable.
- If you change script behavior, update both `SKILL.md` and `README.md` when usage, arguments, or examples change.

## Script Conventions

- Read-only operations: `search`, `get`, `list`, `groups`.
- Write operations: `add`, `edit`, `delete`.
- All commands return `{"success": true, ...}` on success and `{"success": false, "error": "..."}` on failure.
- AppleScript is embedded inline in bash functions via heredoc to `osascript`.

## Validation

After making changes:
- run `bash scripts/contacts.sh search "test"` to verify basic functionality;
- run `shellcheck scripts/contacts.sh` for linting;
- verify `SKILL.md` and `README.md` examples match actual CLI behavior.

## Common Pitfalls

- Contacts.app must be running for AppleScript to work. The script activates it automatically.
- AppleScript string escaping: user input containing quotes or backslashes must be escaped before embedding in AppleScript.
- Large contact databases (500+) may be slow with AppleScript iteration. The `search` command uses `whose name contains` for faster name lookups.
- Birthday year `1604` in Contacts means "year not specified".
