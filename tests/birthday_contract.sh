#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTACT_ADD="$ROOT_DIR/scripts/commands/contact/add.sh"
CONTACT_EDIT="$ROOT_DIR/scripts/commands/contact/edit.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

args_file="$tmpdir/osascript.args"

cat >"$tmpdir/osascript" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\0' "$@" >"$ARGS_FILE"
printf '{"success":true,"message":"stubbed","id":"stub-id"}\n'
EOF

chmod +x "$tmpdir/osascript"

read_nul_args() {
  local file="$1"
  args=()
  while IFS= read -r -d '' arg; do
    args+=("$arg")
  done <"$file"
}

assert_arg() {
  local index="$1"
  local expected="$2"
  local actual="${args[$index]-__MISSING__}"
  [ "$actual" = "$expected" ] || {
    printf 'Unexpected arg at index %s.\nExpected: %s\nActual: %s\n' "$index" "$expected" "$actual" >&2
    exit 1
  }
}

add_output="$(PATH="$tmpdir:$PATH" ARGS_FILE="$args_file" bash "$CONTACT_ADD" --first "John" --last "Doe" --birthday "04-20")"
printf '%s\n' "$add_output" | grep -Eq '"success"[[:space:]]*:[[:space:]]*true' || {
  printf 'Expected add success JSON, got:\n%s\n' "$add_output" >&2
  exit 1
}

read_nul_args "$args_file"
[ "${#args[@]}" -eq 8 ] || {
  printf 'Expected 8 add osascript args including script path, got %s\n' "${#args[@]}" >&2
  exit 1
}
assert_arg 0 "$ROOT_DIR/scripts/applescripts/contact/add.applescript"
assert_arg 1 "John"
assert_arg 2 "Doe"
assert_arg 7 "04-20"

edit_output="$(PATH="$tmpdir:$PATH" ARGS_FILE="$args_file" bash "$CONTACT_EDIT" --id "contact-123" --birthday "1988-04-20")"
printf '%s\n' "$edit_output" | grep -Eq '"success"[[:space:]]*:[[:space:]]*true' || {
  printf 'Expected edit success JSON, got:\n%s\n' "$edit_output" >&2
  exit 1
}

read_nul_args "$args_file"
[ "${#args[@]}" -eq 8 ] || {
  printf 'Expected 8 edit osascript args including script path, got %s\n' "${#args[@]}" >&2
  exit 1
}
assert_arg 0 "$ROOT_DIR/scripts/applescripts/contact/edit.applescript"
assert_arg 1 "id"
assert_arg 2 "contact-123"
assert_arg 7 "1988-04-20"

set +e
invalid_output="$(PATH="$tmpdir:$PATH" ARGS_FILE="$args_file" bash "$CONTACT_EDIT" --id "contact-123" --birthday "04/20" 2>&1)"
invalid_status=$?
set -e

[ "$invalid_status" -eq 1 ] || {
  printf 'Expected invalid birthday to exit 1, got %s\n%s\n' "$invalid_status" "$invalid_output" >&2
  exit 1
}

printf '%s\n' "$invalid_output" | grep -q 'Invalid --birthday: 04/20. Use MM-DD or YYYY-MM-DD' || {
  printf 'Missing invalid birthday error in output:\n%s\n' "$invalid_output" >&2
  exit 1
}

printf 'birthday_contract: ok\n'
