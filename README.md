# macOS Contacts Skill

This repo stores an AI agent skill for Apple Contacts.app on macOS.

The public interface is `scripts/commands`.
`scripts/applescripts/contact` and `scripts/contacts.sh` are internal implementation details.

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

## Purpose And Scope

This skill lets agents:

- search contacts by name, phone, email, or organisation
- read full contact details by exact name or stable contact `id`
- list contacts, optionally by group
- add, edit, and delete contacts with explicit write commands
- list groups
- check Contacts automation access with a health command

## Requirements

- macOS with Contacts.app
- Bash 3.2+ or newer
- `osascript`
- Terminal automation permission for Contacts.app

No extra runtime dependencies are required.

## Public Interface

Run commands from the repo root:

```bash
scripts/commands/<entity>/<action>.sh [args...]
```

Published commands:

- `scripts/commands/contact/search.sh`
- `scripts/commands/contact/get.sh`
- `scripts/commands/contact/list.sh`
- `scripts/commands/contact/add.sh`
- `scripts/commands/contact/edit.sh`
- `scripts/commands/contact/delete.sh`
- `scripts/commands/group/list.sh`
- `scripts/commands/system/doctor.sh`

Compatibility note:

- `scripts/contacts.sh` still works for older callers, but it is not the public interface anymore.
- Do not call `scripts/applescripts/contact/*.applescript` directly.

Unsupported options:

- `--json`
- `--plain`
- `--format=plain|json`

## How To Use

```bash
scripts/commands/contact/search.sh --field name --limit 10 "Doe"
scripts/commands/contact/search.sh --field email --exact "john@example.com"
scripts/commands/contact/get.sh "John Doe"
scripts/commands/contact/get.sh --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"
scripts/commands/contact/list.sh --limit 10
scripts/commands/contact/list.sh --group "Work" --limit 10
scripts/commands/contact/add.sh --first "John" --last "Doe" --phone "+48123456789" --email "john@example.com" --org "Acme" --birthday "04-20"
scripts/commands/contact/add.sh --first "John" --last "Doe" --birthday "1988-04-20"
scripts/commands/contact/edit.sh "John Doe" --phone "+48111222333"
scripts/commands/contact/edit.sh --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson" --email "new@example.com"
scripts/commands/contact/edit.sh "John Doe" --birthday "04-20"
scripts/commands/contact/edit.sh --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson" --birthday "1988-04-20"
scripts/commands/contact/delete.sh --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"
scripts/commands/group/list.sh
scripts/commands/system/doctor.sh
```

## Input And Output Contract

Output rules:

- Commands return JSON on success.
- Logical failures return JSON with `{"success": false, "error": "..."}` and exit with status `1`.
- Success payloads keep the existing envelope `{"success": true, ...}`.

Contact object fields:

- `id`
- `name`
- `phones`
- `emails`
- `addresses`
- `organization`
- `job_title`
- `birthday`
- `note`

Search and list notes:

- `search.sh` supports `--field name|phone|email|org|all`, `--limit N`, and `--exact`.
- `add.sh` and `edit.sh` support `--birthday` in `MM-DD` or `YYYY-MM-DD` format.
- `list.sh` supports `--group` and `--limit`.
- label values are normalised to simple values such as `mobile`, `home`, `work`, and `other`.
- Contacts can return birthday year `1604` when the year is not set.

Example:

```json
{
  "success": true,
  "count": 1,
  "data": [
    {
      "id": "23B708DC-4556-41E3-8738-89867826B760:ABPerson",
      "name": "John Doe",
      "phones": [{"label": "mobile", "value": "+48123456789"}],
      "emails": [{"label": "work", "value": "mail@johndoe.com"}]
    }
  ]
}
```

## Repo Layout

- `AGENTS.md` - repo rules for agents.
- `README.md` - human-facing overview.
- `SKILL.md` - agent-facing workflow and command contract.
- `Makefile` - validation entrypoints.
- `scripts/commands/` - public shell command surface.
- `scripts/applescripts/contact/` - internal AppleScript backends.
- `tests/` - dictionary and smoke checks.

## Validation And Tests

```bash
make check
make compile
make test
```

`make test` runs the dictionary contract and a live smoke test against Contacts.app.

## Known Limits

- Contacts automation can fail until macOS grants Terminal access to Contacts.app.
- AppleScript can be slow on large contact databases.
- The public interface does not expose raw AppleScript internals.
- `scripts/commands/contact/add.sh` keeps the old verb `add` instead of `create` to preserve compatibility with existing callers.

## License

MIT
