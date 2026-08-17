#!/usr/bin/env bash
# Output: JSON (deletion result).
# Backend: AppleScript via scripts/applescripts/contact/delete.applescript.
# Example:
#   scripts/commands/contact/delete.sh --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"
#   scripts/commands/contact/delete.sh "John Doe"
set -euo pipefail

# shellcheck source=scripts/commands/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_lib/common.sh"

usage() {
  cat <<'EOF' >&2
Usage: delete [--id <contact-id>] <full-name>
Delete a contact by full name or by Contacts id.
EOF
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    json_fail "delete requires a contact name or --id"
  fi
  cmd_delete "$@"
}

main "$@"