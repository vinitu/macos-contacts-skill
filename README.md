# macOS Contacts Skill

AI agent skill for managing macOS Contacts.app — search, view, create, edit, and delete contacts via AppleScript.

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

## What it does

This skill gives AI agents (Claude Code, Cursor, Copilot, etc.) the ability to:

- **Search** contacts by name, phone, email, or organization with `--field`, `--limit`, and `--exact`
- **Get** full details of a specific contact by exact name or stable contact `id`
- **List** all contacts or filter by group
- **Add** new contacts with phone, email, and organization
- **Edit** existing contact fields by name or `id`
- **Delete** contacts by name or `id`
- **Groups** — list all contact groups
- **Doctor** — check Contacts automation access and database counts

## How it works

Uses AppleScript via `osascript` to interact with macOS Contacts.app. No external dependencies — just bash and osascript.

The CLI wrapper `scripts/contacts.sh` preserves the stable command-line interface and dispatches to command entrypoints in `scripts/contacts/*.applescript`.

## Requirements

- macOS with Contacts.app
- Bash 3.2+ (ships with macOS)
- Terminal must have Automation permission for Contacts.app

## Quick start

```bash
# Search contacts by name
bash scripts/contacts.sh search --field name --limit 10 "Doe"

# Search contacts by email
bash scripts/contacts.sh search --field email --exact "john@example.com"

# Get full contact details
bash scripts/contacts.sh get "John Doe"

# Get by stable contact id
bash scripts/contacts.sh get --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"

# List contacts
bash scripts/contacts.sh list --limit 10

# List contacts in a group
bash scripts/contacts.sh list --group "Work" --limit 10

# Add a contact
bash scripts/contacts.sh add --first "John" --last "Doe" --phone "+48123456789" --email "john@example.com" --org "Acme"

# Edit a contact by name
bash scripts/contacts.sh edit "John Doe" --phone "+48111222333"

# Edit a contact by stable contact id
bash scripts/contacts.sh edit --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson" --email "new@example.com"

# Delete a contact by name
bash scripts/contacts.sh delete "John Doe"

# Delete a contact by stable contact id
bash scripts/contacts.sh delete --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"

# List groups
bash scripts/contacts.sh groups

# Check Contacts automation health
bash scripts/contacts.sh doctor
```

## Commands

### `search`

```bash
# Search across name and organization
bash scripts/contacts.sh search "John"

# Search by exact email
bash scripts/contacts.sh search --field email --exact "john@example.com"

# Search by phone
bash scripts/contacts.sh search --field phone "+48123456789"

# Limit results
bash scripts/contacts.sh search --field name --limit 5 "Doe"
```

### `get`

```bash
# Get by exact full name
bash scripts/contacts.sh get "John Doe"

# Get by stable contact id
bash scripts/contacts.sh get --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"
```

### `list`

```bash
# List first 10 contacts
bash scripts/contacts.sh list --limit 10

# List contacts in a group
bash scripts/contacts.sh list --group "Work"

# List contacts in a group with limit
bash scripts/contacts.sh list --group "Work" --limit 10
```

### `add`

```bash
# Add a minimal contact
bash scripts/contacts.sh add --first "John" --last "Doe"

# Add a full contact
bash scripts/contacts.sh add --first "John" --last "Doe" --phone "+48123456789" --email "john@example.com" --org "Acme" --title "CTO"
```

### `edit`

```bash
# Add a phone to a contact found by name
bash scripts/contacts.sh edit "John Doe" --phone "+48111222333"

# Add an email to a contact found by id
bash scripts/contacts.sh edit --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson" --email "new@example.com"

# Update organization and title
bash scripts/contacts.sh edit "John Doe" --org "NewCorp" --title "CTO"
```

### `delete`

```bash
# Delete by name
bash scripts/contacts.sh delete "John Doe"

# Delete by stable contact id
bash scripts/contacts.sh delete --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"
```

### `groups`

```bash
bash scripts/contacts.sh groups
```

### `doctor`

```bash
bash scripts/contacts.sh doctor
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/contacts.sh` | Main CLI dispatcher — stable command interface |
| `scripts/contacts/*.applescript` | Command entrypoints used by the CLI wrapper |
| `tests/smoke_contacts.sh` | Read-only smoke test for JSON output and exit codes |

## Output

All commands return JSON for easy integration with AI agents and automation tools.
Logical failures return `{"success": false, ...}` and exit with status `1`.
Contact payloads include a stable `id`.
Phone and email labels are normalized to values like `mobile`, `home`, `work`, and `other`.
Use `--field phone` or `--field email` for precise non-name lookups.

```json
{
  "success": true,
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

## License

MIT
