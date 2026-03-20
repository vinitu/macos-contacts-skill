#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/doctor.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '{"success":false,"error":"Contacts automation check failed: Not authorized"}\n'
exit 1
EOF

cat >"$tmpdir/unexpected.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'unexpected command call\n' >&2
exit 99
EOF

chmod +x "$tmpdir/doctor.sh" "$tmpdir/unexpected.sh"

output="$(
  CONTACT_CLI="$tmpdir" \
  GROUP_CLI="$tmpdir/unexpected.sh" \
  SYSTEM_CLI="$tmpdir/doctor.sh" \
  LEGACY_CLI="$tmpdir/unexpected.sh" \
  bash "$ROOT_DIR/tests/smoke_contacts.sh"
)"

printf '%s\n' "$output" | grep -q 'Skipping smoke tests: Contacts automation unavailable.' || {
  printf 'Expected skip message, got:\n%s\n' "$output" >&2
  exit 1
}

printf '%s\n' "$output" | grep -q '"success":false' || {
  printf 'Expected doctor failure JSON in skip output, got:\n%s\n' "$output" >&2
  exit 1
}

printf 'smoke_skip_contract: ok\n'
