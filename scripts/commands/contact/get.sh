#!/usr/bin/env bash
# Output: JSON (single contact).
# Backend: AppleScript via scripts/applescripts/contact/get.applescript.
# Example:
#   scripts/commands/contact/get.sh "John Doe"
#   scripts/commands/contact/get.sh --id "23B708DC-4556-41E3-8738-89867826B760:ABPerson"
set -euo pipefail

# shellcheck source=scripts/commands/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_lib/common.sh"

usage() {
  cat <<'EOF' >&2
Usage: get [--id <contact-id>] <full-name>
Return one contact by full name or by Contacts id.
EOF
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    json_fail "get requires a contact name or --id"
  fi
  cmd_get "$@"
}

main "$@"