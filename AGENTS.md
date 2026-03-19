# Repo Guide

## Purpose

This repo stores an AI agent skill for Apple Contacts.app on macOS.
It keeps a stable JSON command surface for agents while using AppleScript internally.
Read actions stay safe by default. Write actions must be explicit.

Installed global skill directory: `~/.agents/skills/macos-contacts`.
`skills check` and `skills update` may refer to this skill by upstream package name `apple-contacts` from `vinitu/apple-contacts-skill`.

## Source of Truth

- `SKILL.md` is the source of truth for the public command surface and output contract.
- `README.md` is the human-facing overview and setup guide.
- `scripts/commands/` is the only public interface.
- `scripts/applescripts/contact/` and `scripts/contacts.sh` are internal implementation details.
- `make dictionary-contacts` and live `osascript` checks are the source of truth for Contacts.app coverage.

## Repository Layout

- `AGENTS.md` - rules for future agents.
- `README.md` - repo overview, installation, and validation notes.
- `SKILL.md` - agent-facing workflow and command reference.
- `Makefile` - standard entrypoints for `check`, `compile`, and `test`.
- `scripts/commands/contact/*.sh` - public contact commands.
- `scripts/commands/group/list.sh` - public command for contact groups.
- `scripts/commands/system/doctor.sh` - public health check command.
- `scripts/applescripts/contact/*.applescript` - internal AppleScript backends.
- `scripts/contacts.sh` - internal compatibility wrapper for the older single-entrypoint CLI.
- `tests/dictionary_contract.sh` - Contacts dictionary contract check.
- `tests/smoke_contacts.sh` - smoke test for the public command surface.

## Working Rules

- Use only `scripts/commands` in docs, tests, and skill instructions.
- Do not call `scripts/applescripts` directly from the public contract.
- Keep the runtime dependency-free: `bash` and `osascript` only.
- Preserve JSON output as the integration boundary. Success and failure output must stay machine-readable.
- Treat contact data as real user data. Do not create, edit, or delete records unless the task clearly requires it.
- Keep legacy `scripts/contacts.sh` working unless the user explicitly approves a breaking change.
- Update `SKILL.md` and `README.md` whenever command coverage, examples, or output shapes change.

## Validation Commands

After making changes:
- run `make check`
- run `make compile`
- run `make test`
- run `shellcheck $(find scripts tests -name '*.sh' -print)`
- run one manual public command such as `bash scripts/commands/contact/search.sh "test"`

## Common Pitfalls

- Contacts automation may fail until Terminal has Automation permission for Contacts.app.
- Contacts.app can be slow on large address books, especially for wide searches.
- AppleScript string escaping must stay correct for quotes, backslashes, and newlines.
- Birthday year `1604` in Contacts means the year is not set.
- `scripts/contacts.sh` is kept only for compatibility; do not present it as the public interface.
