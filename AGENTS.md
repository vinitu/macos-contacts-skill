# Repo Guide

This repo stores an AI agent skill for macOS Contacts.app.

Installed global skill directory: `~/.agents/skills/macos-contacts`.
`skills check` and `skills update` may refer to this skill by upstream package name `apple-contacts` from `vinitu/apple-contacts-skill`.

## Where to start

- Read this file, then `SKILL.md` for the full command list and usage.
- Run all commands from the **repo root**: `./scripts/commands/<entity>/<action>.sh` or `scripts/commands/...`
- Do not call `scripts/applescripts` directly; use only `scripts/commands`.

## Goal

- Keep the AppleScript coverage accurate to the live Contacts.app dictionary.
- Keep the public `scripts/commands` interface accurate to the implemented behavior.
- Prefer runnable examples over long prose.
- Treat contact data as real user data. Read actions are safe by default; write actions must be explicit.

## Source of truth

- `make dictionary-contacts` / `make dictionary-standard` dump the live Contacts.app and Cocoa standard dictionaries (`sdef /System/Applications/Contacts.app`).
- Live checks with `osascript` against `scripts/applescripts/contact/*.applescript` are the source of truth for Contacts.app coverage.
- `SKILL.md` is the source of truth for the public command surface and output contract.
- Raw dictionary commands live only in this file and in the `Makefile`.

## Public vs Internal separation

- **Public interface**: `scripts/commands/**` — the only surface documented in `SKILL.md`, `README.md`, tests, and skill instructions. Run from the repo root.
- **Internal backend**: `scripts/applescripts/contact/*.applescript` — invoked via `osascript` by the command wrappers. Never call these directly from the public contract or skill instructions.
- Only commands listed in `SKILL.md` are public. Other scripts may exist for internal use or legacy cleanup.

## Repo layout

- **AGENTS.md** — rules for future agents.
- **README.md** — repo overview for humans.
- **SKILL.md** — main skill workflow and full command list; update when command coverage changes.
- **Makefile** — helper commands for dictionary dump, `compile`, `check`, and `test`.
- **scripts/commands/contact/*.sh** — public contact commands.
- **scripts/commands/group/list.sh** — public command for contact groups.
- **scripts/commands/system/doctor.sh** — public health check command.
- **scripts/commands/_lib/common.sh** — shared shell helpers and `cmd_*` implementations sourced by the command wrappers.
- **scripts/applescripts/contact/*.applescript** — internal AppleScript backends.
- **tests/dictionary_contract.sh** — Contacts dictionary contract check.
- **tests/smoke_contacts.sh** — live smoke test for the public command surface.

## Example (search)

```bash
./scripts/commands/contact/search.sh --field name --limit 10 "John"
./scripts/commands/contact/search.sh --field email --exact "john@example.com"
./scripts/commands/contact/get.sh --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"
./scripts/commands/group/list.sh
```

## Safety rules

- Read commands (`search`, `get`, `list`, `groups`, `doctor`) are safe by default.
- Write commands (`add`, `edit`, `delete`) are explicit and mutate real user data. Do not run them unless the task clearly requires it.
- Treat contact records as real user data. Never send, delete, move, overwrite, or export records without explicit user approval.
- Verify documented commands against the live app dictionary before claiming support.
- Preserve JSON output shape and existing flags unless a breaking change is requested.
- Keep the runtime dependency-free: `bash` and `osascript` only.
- **Test data**: any smoke test or manual check that creates disposable contacts must use the `CodexTest_` name prefix and clean up (delete) every record it creates. Never leave temporary contacts behind.

## Editing rules

- Keep docs in simple English.
- Use only `scripts/commands` in docs, tests, and skill instructions.
- Do not call `scripts/applescripts` directly from the public contract.
- Update `SKILL.md` and `README.md` whenever command coverage, examples, or output shapes change.
- Preserve JSON output as the integration boundary. Success and failure output must stay machine-readable.
- Call out "declared by the standard suite" vs "verified in Contacts" when relevant.

## Validation

- After AppleScript or command changes: `make compile` then `make test`.
- Useful targets: `dictionary-contacts`, `dictionary-standard`, `compile`, `check`, `test`.
- `make check` verifies Contacts.app is reachable before running smoke tests.
- Smoke tests (`make test-smoke`) require Contacts.app and Contacts automation access; they can be slow.
- `shellcheck $(find scripts tests -name '*.sh' -print)` for shell lint.

## Pitfalls / Env limits

- Contacts automation may fail until macOS grants the calling Terminal/agent **Automation** (and in some cases **Contacts**) TCC permission for Contacts.app (System Settings → Privacy & Security → Automation / Contacts). Document TCC or app-state blocks clearly instead of retrying destructive actions.
- Contacts.app can be slow on large address books, especially for wide searches.
- AppleScript string escaping must stay correct for quotes, backslashes, and newlines.
- Birthday year `1604` in Contacts means the year is not set.
- If Contacts automation is blocked by macOS permissions, report that clearly instead of retrying destructive actions.