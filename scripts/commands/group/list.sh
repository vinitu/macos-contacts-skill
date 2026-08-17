#!/usr/bin/env bash
# Output: JSON (array of contact groups).
# Backend: AppleScript via scripts/applescripts/contact/groups.applescript.
# Example:
#   scripts/commands/group/list.sh
set -euo pipefail

# shellcheck source=scripts/commands/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_lib/common.sh"

usage() {
  cat <<'EOF' >&2
Usage: list
List all contact groups.
EOF
}

main() {
  cmd_groups "$@"
}

main "$@"