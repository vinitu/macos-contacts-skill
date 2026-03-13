#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

make --no-print-directory dictionary-contacts >"$tmp"

has_pattern() {
	local pattern="$1"
	if command -v rg >/dev/null 2>&1; then rg -q "$pattern" "$tmp"; else grep -q -- "$pattern" "$tmp"; fi
}

has_pattern '<class name="person"'
has_pattern '<class name="group"'

printf 'dictionary_contract: ok\n'
