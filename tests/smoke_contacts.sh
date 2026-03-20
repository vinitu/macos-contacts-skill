#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTACT_CLI="${CONTACT_CLI:-$ROOT_DIR/scripts/commands/contact}"
GROUP_CLI="${GROUP_CLI:-$ROOT_DIR/scripts/commands/group/list.sh}"
SYSTEM_CLI="${SYSTEM_CLI:-$ROOT_DIR/scripts/commands/system/doctor.sh}"
LEGACY_CLI="${LEGACY_CLI:-$ROOT_DIR/scripts/contacts.sh}"

assert_success_json() {
  local output="$1"
  printf '%s\n' "$output" | grep -Eq '"success"[[:space:]]*:[[:space:]]*true' || {
    printf 'Expected success JSON, got:\n%s\n' "$output" >&2
    exit 1
  }
}

assert_failure_json() {
  local output="$1"
  printf '%s\n' "$output" | grep -Eq '"success"[[:space:]]*:[[:space:]]*false' || {
    printf 'Expected failure JSON, got:\n%s\n' "$output" >&2
    exit 1
  }
}

extract_first_string_field() {
  local field="$1"
  local output="$2"
  printf '%s\n' "$output" | sed -n "s/.*\"$field\": \"\\([^\"]*\\)\".*/\\1/p" | head -n1
}

set +e
doctor_output="$(bash "$SYSTEM_CLI" 2>&1)"
doctor_status=$?
set -e

if [ "$doctor_status" -ne 0 ]; then
  printf 'Skipping smoke tests: Contacts automation unavailable.\n%s\n' "$doctor_output"
  exit 0
fi

assert_success_json "$doctor_output"

groups_output="$(bash "$GROUP_CLI")"
assert_success_json "$groups_output"

list_output="$(bash "$CONTACT_CLI/list.sh" --limit 1)"
assert_success_json "$list_output"

first_id="$(extract_first_string_field "id" "$list_output")"
first_name="$(extract_first_string_field "name" "$list_output")"

if [ -n "$first_id" ]; then
  get_by_id_output="$(bash "$CONTACT_CLI/get.sh" --id "$first_id")"
  assert_success_json "$get_by_id_output"
fi

if [ -n "$first_name" ]; then
  search_term="${first_name%% *}"
  [ -z "$search_term" ] && search_term="$first_name"
  search_output="$(bash "$CONTACT_CLI/search.sh" --field name --limit 5 "$search_term")"
  assert_success_json "$search_output"
fi

legacy_groups_output="$(bash "$LEGACY_CLI" groups)"
assert_success_json "$legacy_groups_output"

set +e
missing_output="$(bash "$CONTACT_CLI/get.sh" "__CODEX_CONTACT_DOES_NOT_EXIST__" 2>&1)"
missing_status=$?
set -e

[ "$missing_status" -eq 1 ] || {
  printf 'Expected missing contact to exit 1, got %s\n%s\n' "$missing_status" "$missing_output" >&2
  exit 1
}

assert_failure_json "$missing_output"

if printf '%s\n' "$list_output" | grep -q '_\$!<'; then
  printf 'Found raw Contacts labels in list output:\n%s\n' "$list_output" >&2
  exit 1
fi

printf 'Smoke tests passed.\n'
