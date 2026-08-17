#!/usr/bin/env bash
# Output: JSON (array of contacts).
# Backend: AppleScript via scripts/applescripts/contact/list.applescript.
# Example:
#   scripts/commands/contact/list.sh --limit 20
#   scripts/commands/contact/list.sh --group "Work"
set -euo pipefail

# shellcheck source=scripts/commands/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_lib/common.sh"

usage() {
  cat <<'EOF' >&2
Usage: list [--group <group-name>] [--limit N]
List contacts, optionally filtered by group. Default limit: 50.
EOF
}

main() {
  cmd_list "$@"
}

main "$@"