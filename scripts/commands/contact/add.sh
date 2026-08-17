#!/usr/bin/env bash
# Output: JSON (created contact).
# Backend: AppleScript via scripts/applescripts/contact/add.applescript.
# Example:
#   scripts/commands/contact/add.sh --first "John" --last "Doe" --phone "+48123456789"
#   scripts/commands/contact/add.sh --first "John" --last "Doe" --birthday "1988-04-20"
set -euo pipefail

# shellcheck source=scripts/commands/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_lib/common.sh"

usage() {
  cat <<'EOF' >&2
Usage: add --first <name> --last <name> [--phone <num>] [--email <addr>] [--org <company>] [--title <title>] [--birthday <MM-DD|YYYY-MM-DD>]
Create a new contact. At least --first or --last is required.
EOF
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    json_fail "add requires at least --first or --last"
  fi
  cmd_add "$@"
}

main "$@"