#!/usr/bin/env bash
# Output: JSON (updated contact).
# Backend: AppleScript via scripts/applescripts/contact/edit.applescript.
# Example:
#   scripts/commands/contact/edit.sh "John Doe" --phone "+48111222333"
#   scripts/commands/contact/edit.sh --id "ID" --email "new@example.com"
#   scripts/commands/contact/edit.sh --id "ID" --clear-birthday
set -euo pipefail

# shellcheck source=scripts/commands/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_lib/common.sh"

usage() {
  cat <<'EOF' >&2
Usage: edit [--id <contact-id>] <full-name> [--phone <num>] [--email <addr>] [--org <company>] [--title <title>] [--birthday <MM-DD|YYYY-MM-DD>] [--clear-birthday]
Update fields on an existing contact. Provide at least one field to update.
EOF
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    json_fail "edit requires a contact name or --id plus fields to update"
  fi
  cmd_edit "$@"
}

main "$@"