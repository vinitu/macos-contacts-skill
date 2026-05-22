# macOS Contacts Skill

This repo stores an AI agent skill for Apple Contacts.app on macOS.

The public interface is `scripts/commands`.
`scripts/applescripts/contact` stores internal AppleScript backends and dictionary-aligned coverage.

## Installation

```bash
npx skills add vinitu/apple-contacts-skill
```

Or with [skills.sh](https://skills.sh):

```bash
skills.sh add vinitu/apple-contacts-skill
```

The installed global skill directory is usually `~/.agents/skills/macos-contacts`.
`skills check` and `skills update` may refer to the upstream package name `apple-contacts`.

## Prerequisites

- macOS with Contacts.app
- Bash 3.2+ or newer
- `osascript`
- Terminal automation permission for Contacts.app

## Public Interface

Run skill actions with:

```bash
scripts/commands/<entity>/<action>.sh [args...]
```

Output rules:

- Commands return JSON by default unless noted otherwise.
- `--json`, `--plain`, and `--format=plain|json` are not supported.

## Backend Map

- `scripts/commands/contact/*` → AppleScript in `scripts/applescripts/contact/*`
- `scripts/commands/group/*` → AppleScript in `scripts/applescripts/contact/*` (groups, list)
- `scripts/commands/system/*` → AppleScript in `scripts/applescripts/contact/*` (doctor)

`scripts/applescripts` is internal. Do not call it directly from the skill instructions.

## Command Surface

Contact:

- `scripts/commands/contact/search.sh`
- `scripts/commands/contact/get.sh`
- `scripts/commands/contact/list.sh`
- `scripts/commands/contact/add.sh`
- `scripts/commands/contact/edit.sh`
- `scripts/commands/contact/delete.sh`

Group:

- `scripts/commands/group/list.sh`

System:

- `scripts/commands/system/doctor.sh`

## JSON Contract

Success envelope:

- `success`: `true`
- command-specific fields such as `count`, `data`, `id`, `name`, or `message`

Failure envelope:

- `success`: `false`
- `error`: string

Contact object:

- `id`
- `name`
- `phones`
- `emails`
- `addresses`
- `organization`
- `job_title`
- `birthday`
- `note`

Search and list rules:

- `search.sh` supports `--field name|phone|email|org|all`, `--limit N`, and `--exact`
- `add.sh` and `edit.sh` support `--birthday` in `MM-DD` or `YYYY-MM-DD` format
- `edit.sh` supports `--clear-birthday` to remove an existing birthday
- use `--field phone` or `--field email` for exact lookups by number or email
- phone, email, and address labels are normalised to values such as `mobile`, `home`, `work`, and `other`
- Contacts can return birthday year `1604` when the year is not set

## Validation

```bash
make compile
make test
```

`make test` runs live checks against Contacts.app and expects Contacts automation access. `make check` verifies Contacts is accessible before running smoke tests.

## Known Limits

- Contacts automation can fail until macOS grants Terminal access to Contacts.app.
- AppleScript can be slow on large contact databases.
- The public interface does not expose raw AppleScript internals.

## License

MIT
