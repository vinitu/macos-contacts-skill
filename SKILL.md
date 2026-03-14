---
name: macos-contacts
description: Manage macOS Contacts.app — search, view, create, edit, and delete contacts. Use when the user asks to find a contact, look up a phone number or email, add a new contact, update contact details, or list contact groups.
---

# macOS Contacts Skill

## Overview
- Manages macOS Contacts.app through AppleScript.
- No external dependencies — uses only bash and osascript.
- Main CLI wrapper: `scripts/contacts.sh`.
- Command entrypoints: `scripts/contacts/*.applescript`.
- All commands return JSON for agent consumption.
- Installed global skill directory: `~/.agents/skills/macos-contacts`.
- `skills check` and `skills update` may refer to this skill by upstream package name `apple-contacts` from `vinitu/apple-contacts-skill`.

## Quick Start

```bash
# Search for a contact by name
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh search --field name --limit 10 "John"

# Search for a contact by email
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh search --field email --exact "john@example.com"

# Get full details of a contact
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh get "John Doe"

# Get full details by stable contact id
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh get --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"

# List contacts
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh list --limit 20

# List contacts in a group
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh list --group "Work"

# Add a new contact
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh add --first "John" --last "Doe" --phone "+48123456789" --email "john@example.com" --org "Acme"

# Edit a contact by name
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh edit "John Doe" --phone "+48111222333"

# Edit a contact by stable contact id
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh edit --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson" --email "new@example.com"

# Delete a contact by name
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh delete "John Doe"

# Delete a contact by stable contact id
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh delete --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"

# List all contact groups
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh groups

# Check Contacts automation health
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh doctor
```

## What This Skill Can Do

### `search`

```bash
# Search across name and organization
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh search "John"

# Search by exact email
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh search --field email --exact "john@example.com"

# Search by phone
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh search --field phone "+48123456789"

# Limit results
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh search --field name --limit 5 "Doe"
```

### `get`

```bash
# Get by exact full name
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh get "John Doe"

# Get by stable contact id
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh get --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"
```

### `list`

```bash
# List first 20 contacts
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh list --limit 20

# List contacts in a group
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh list --group "Work"

# List contacts in a group with limit
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh list --group "Work" --limit 10
```

### `add`

```bash
# Add a minimal contact
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh add --first "John" --last "Doe"

# Add a full contact
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh add --first "John" --last "Doe" --phone "+48123456789" --email "john@example.com" --org "Acme" --title "CTO"
```

### `edit`

```bash
# Add a phone to a contact found by name
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh edit "John Doe" --phone "+48111222333"

# Add an email to a contact found by id
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh edit --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson" --email "new@example.com"

# Update organization and title
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh edit "John Doe" --org "NewCorp" --title "CTO"
```

### `delete`

```bash
# Delete by name
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh delete "John Doe"

# Delete by stable contact id
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh delete --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"
```

### `groups`

```bash
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh groups
```

### `doctor`

```bash
bash ~/.agents/skills/macos-contacts/scripts/contacts.sh doctor
```

## Operational Notes
- Default output is JSON — do not dump raw JSON to the user; summarize naturally.
- Search supports `--field name|phone|email|org|all`, `--limit N`, and `--exact`.
- Use `--field phone` or `--field email` when the query is primarily a number or email lookup.
- Contact payloads include a stable `id`.
- Phone, email, and address labels are normalized to simple values like `mobile`, `home`, `work`, and `other`.
- The `get` command returns: name, phones, emails, addresses, organization, job title, birthday, and notes.
- The `add` command requires at least `--first` or `--last`.
- `get`, `edit`, and `delete` can target an exact full name or `--id`.
- Logical failures return `{"success": false, ...}` and exit with code `1`.
- Contacts.app must be running (the script activates it automatically).
