#!/usr/bin/env bash
# Output: JSON (array of matching contacts).
# Backend: AppleScript via scripts/applescripts/contact/search.applescript.
# Example:
#   scripts/commands/contact/search.sh --field name --limit 10 "John"
#   scripts/commands/contact/search.sh --field email --exact "john@example.com"
set -euo pipefail

# shellcheck source=scripts/commands/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_lib/common.sh"

usage() {
  cat <<'EOF' >&2
Usage: search [--field name|phone|email|org|all] [--limit N] [--exact] <query>
Search contacts by field. Defaults: --field all, --limit 20.
EOF
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    json_fail "search requires a query"
  fi
  cmd_search "$@"
}

main "$@"