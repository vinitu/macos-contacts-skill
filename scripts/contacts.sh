#!/usr/bin/env bash
# Compatibility wrapper for the older single-entrypoint Contacts CLI.
# Public commands live under scripts/commands/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLEScript_DIR="$SCRIPT_DIR/applescripts/contact"

json_escape() {
  local s="${1-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

json_error() {
  printf '{"success":false,"error":"%s"}\n' "$(json_escape "$1")"
  exit 1
}

require_option_value() {
  local flag="$1"
  local value="${2-}"
  [ -n "$value" ] || json_error "Missing value for $flag"
}

validate_positive_int() {
  local flag="$1"
  local value="$2"
  [[ "$value" =~ ^[0-9]+$ ]] || json_error "Invalid $flag: $value"
  [ "$value" -ge 1 ] || json_error "Invalid $flag: $value"
}

validate_birthday() {
  local value="$1"
  [[ "$value" =~ ^([0-9]{2}-[0-9]{2}|[0-9]{4}-[0-9]{2}-[0-9]{2})$ ]] || json_error "Invalid --birthday: $value. Use MM-DD or YYYY-MM-DD"
}

assert_no_conflict() {
  local set_flag="$1"
  local clear_flag="$2"
  local label="$3"
  if [ "$set_flag" = "true" ] && [ "$clear_flag" = "true" ]; then
    json_error "Conflicting options for $label"
  fi
}

run_applescript() {
  local output

  if ! output="$("$@" 2>&1)"; then
    json_error "$output"
  fi

  printf '%s\n' "$output"

  case "$output" in
    *'"success": false'*|*'"success":false'*)
      exit 1
      ;;
  esac
}

run_contacts_applescript() {
  local operation="$1"
  shift

  local script_path="$APPLEScript_DIR/${operation}.applescript"
  [ -f "$script_path" ] || json_error "Missing AppleScript entrypoint: $script_path"

  run_applescript osascript "$script_path" "$@"
}

cmd_search() {
  local field="all"
  local limit="20"
  local exact="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --field)
        require_option_value "$1" "${2-}"
        field="$2"
        shift 2
        ;;
      --limit)
        require_option_value "$1" "${2-}"
        limit="$2"
        shift 2
        ;;
      --exact)
        exact="true"
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        json_error "Unknown option for search: $1"
        ;;
      *)
        break
        ;;
    esac
  done

  local query="${*:-}"
  [ -z "$query" ] && json_error "Usage: contacts.sh search [--field name|phone|email|org|all] [--limit N] [--exact] <query>"

  case "$field" in
    all|name|phone|email|org|organization) ;;
    *) json_error "Invalid --field: $field" ;;
  esac

  [ "$field" = "organization" ] && field="org"
  validate_positive_int "--limit" "$limit"

  run_contacts_applescript search "$query" "$field" "$limit" "$exact"
}

cmd_get() {
  local selector_mode="name"
  local selector=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)
        require_option_value "$1" "${2-}"
        selector_mode="id"
        selector="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        json_error "Unknown option for get: $1"
        ;;
      *)
        break
        ;;
    esac
  done

  if [[ -z "$selector" ]]; then
    selector="${*:-}"
  fi

  [ -z "$selector" ] && json_error "Usage: contacts.sh get [--id <contact-id>] <full-name>"

  run_contacts_applescript get "$selector_mode" "$selector"
}

cmd_list() {
  local group=""
  local limit="50"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --group)
        require_option_value "$1" "${2-}"
        group="$2"
        shift 2
        ;;
      --limit)
        require_option_value "$1" "${2-}"
        limit="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        json_error "Unknown option for list: $1"
        ;;
      *)
        json_error "Unexpected argument for list: $1"
        ;;
    esac
  done

  validate_positive_int "--limit" "$limit"
  run_contacts_applescript list "$group" "$limit"
}

cmd_add() {
  local first=""
  local last=""
  local phone=""
  local email=""
  local org=""
  local title=""
  local birthday=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --first)
        require_option_value "$1" "${2-}"
        first="$2"
        shift 2
        ;;
      --last)
        require_option_value "$1" "${2-}"
        last="$2"
        shift 2
        ;;
      --phone)
        require_option_value "$1" "${2-}"
        phone="$2"
        shift 2
        ;;
      --email)
        require_option_value "$1" "${2-}"
        email="$2"
        shift 2
        ;;
      --org)
        require_option_value "$1" "${2-}"
        org="$2"
        shift 2
        ;;
      --title)
        require_option_value "$1" "${2-}"
        title="$2"
        shift 2
        ;;
      --birthday)
        require_option_value "$1" "${2-}"
        birthday="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        json_error "Unknown option for add: $1"
        ;;
      *)
        json_error "Unexpected argument for add: $1"
        ;;
    esac
  done

  [ -z "$first" ] && [ -z "$last" ] && json_error "Usage: contacts.sh add --first <name> --last <name> [--phone <num>] [--email <addr>] [--org <company>] [--title <title>] [--birthday <MM-DD|YYYY-MM-DD>]"
  [ -n "$birthday" ] && validate_birthday "$birthday"

  run_contacts_applescript add "$first" "$last" "$phone" "$email" "$org" "$title" "$birthday"
}

cmd_edit() {
  local selector_mode="name"
  local selector=""
  local phone=""
  local email=""
  local org=""
  local title=""
  local birthday=""
  local clear_birthday="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)
        require_option_value "$1" "${2-}"
        selector_mode="id"
        selector="$2"
        shift 2
        ;;
      --phone)
        require_option_value "$1" "${2-}"
        phone="$2"
        shift 2
        ;;
      --email)
        require_option_value "$1" "${2-}"
        email="$2"
        shift 2
        ;;
      --org)
        require_option_value "$1" "${2-}"
        org="$2"
        shift 2
        ;;
      --title)
        require_option_value "$1" "${2-}"
        title="$2"
        shift 2
        ;;
      --birthday)
        require_option_value "$1" "${2-}"
        birthday="$2"
        shift 2
        ;;
      --clear-birthday)
        clear_birthday="true"
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        json_error "Unknown option for edit: $1"
        ;;
      *)
        if [[ -n "$selector" && "$selector_mode" == "id" ]]; then
          json_error "Unexpected argument for edit: $1"
        fi
        selector="${selector:+$selector }$1"
        shift
        ;;
    esac
  done

  [ -z "$selector" ] && json_error "Usage: contacts.sh edit [--id <contact-id>] <full-name> [--phone <num>] [--email <addr>] [--org <company>] [--title <title>] [--birthday <MM-DD|YYYY-MM-DD>] [--clear-birthday]"
  assert_no_conflict "${birthday:+true}" "$clear_birthday" "--birthday"
  [ -z "$phone" ] && [ -z "$email" ] && [ -z "$org" ] && [ -z "$title" ] && [ -z "$birthday" ] && [ "$clear_birthday" != "true" ] && json_error "Nothing to update. Provide at least one of --phone, --email, --org, --title, --birthday, --clear-birthday"
  [ -n "$birthday" ] && validate_birthday "$birthday"

  run_contacts_applescript edit "$selector_mode" "$selector" "$phone" "$email" "$org" "$title" "$birthday" "$clear_birthday"
}

cmd_delete() {
  local selector_mode="name"
  local selector=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)
        require_option_value "$1" "${2-}"
        selector_mode="id"
        selector="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        json_error "Unknown option for delete: $1"
        ;;
      *)
        if [[ -n "$selector" && "$selector_mode" == "id" ]]; then
          json_error "Unexpected argument for delete: $1"
        fi
        selector="${selector:+$selector }$1"
        shift
        ;;
    esac
  done

  [ -z "$selector" ] && json_error "Usage: contacts.sh delete [--id <contact-id>] <full-name>"

  run_contacts_applescript delete "$selector_mode" "$selector"
}

cmd_groups() {
  run_contacts_applescript groups
}

cmd_doctor() {
  run_contacts_applescript doctor
}

# --- Main dispatch ---
CMD="${1:-}"
shift || true

case "$CMD" in
  search)  cmd_search "$@" ;;
  get)     cmd_get "$@" ;;
  list)    cmd_list "$@" ;;
  add)     cmd_add "$@" ;;
  edit)    cmd_edit "$@" ;;
  delete)  cmd_delete "$@" ;;
  groups)  cmd_groups ;;
  doctor)  cmd_doctor ;;
  *)       json_error "Unknown command: $CMD. Available: search, get, list, add, edit, delete, groups, doctor" ;;
esac
