#!/bin/bash
# Manage macOS Contacts.app via AppleScript / JXA.
# Usage:
#   contacts.sh search [--field name|phone|email|org|all] [--limit N] [--exact] <query>
#   contacts.sh get [--id <contact-id>] <full-name>
#   contacts.sh list [--group <name>] [--limit N]
#   contacts.sh add --first <name> --last <name> [--phone <num>] [--email <addr>] [--org <company>] [--title <title>]
#   contacts.sh edit [--id <contact-id>] <full-name> [--phone <num>] [--email <addr>] [--org <company>] [--title <title>]
#   contacts.sh delete [--id <contact-id>] <full-name>
#   contacts.sh groups
#   contacts.sh doctor

set -euo pipefail

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

run_jxa() {
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

  run_jxa osascript -l JavaScript - "$query" "$field" "$limit" "$exact" <<'EOF'
function normalizeLabel(label) {
  const raw = String(label || "");
  const known = {
    "_$!<Mobile>!$_": "mobile",
    "_$!<Home>!$_": "home",
    "_$!<Work>!$_": "work",
    "_$!<Main>!$_": "main",
    "_$!<Other>!$_": "other",
    "_$!<HomePage>!$_": "homepage",
    "_$!<School>!$_": "school",
    "_$!<iPhone>!$_": "iphone",
    "Phone": "phone"
  };

  if (Object.prototype.hasOwnProperty.call(known, raw)) {
    return known[raw];
  }

  const tokenMatch = raw.match(/^_\$!<(.*)>!\$_$/);
  if (tokenMatch) {
    return tokenMatch[1].toLowerCase().replace(/\s+/g, "-");
  }

  return raw.toLowerCase().replace(/\s+/g, "-");
}

function personEntry(person) {
  const entry = {
    id: person.id(),
    name: person.name()
  };

  try {
    const phones = person.phones();
    if (phones.length > 0) {
      entry.phones = phones.map(phone => ({
        label: normalizeLabel(phone.label()),
        value: phone.value()
      }));
    }
  } catch (error) {}

  try {
    const emails = person.emails();
    if (emails.length > 0) {
      entry.emails = emails.map(email => ({
        label: normalizeLabel(email.label()),
        value: email.value()
      }));
    }
  } catch (error) {}

  try {
    const organization = person.organization();
    if (organization) {
      entry.organization = organization;
    }
  } catch (error) {}

  return entry;
}

function addUnique(target, seen, person) {
  const personId = person.id();
  if (seen.has(personId)) {
    return false;
  }
  seen.add(personId);
  target.push(person);
  return true;
}

function matchesValue(value, query, exact) {
  if (!value) {
    return false;
  }

  const left = String(value).toLowerCase();
  const right = query.toLowerCase();
  return exact ? left === right : left.includes(right);
}

function run(argv) {
  const [rawQuery, fieldArg, limitArg, exactArg] = argv;
  const query = rawQuery || "";
  const field = String(fieldArg || "all").toLowerCase();
  const exact = exactArg === "true";
  const limit = Number(limitArg);
  const validFields = new Set(["all", "name", "phone", "email", "org", "organization"]);

  if (!validFields.has(field)) {
    return JSON.stringify({success: false, error: "Invalid --field: " + fieldArg});
  }

  if (!Number.isInteger(limit) || limit < 1) {
    return JSON.stringify({success: false, error: "Invalid --limit: " + limitArg});
  }

  const normalizedField = field === "organization" ? "org" : field;
  const detailLikeQuery = /[@+0-9]/.test(query);
  const app = Application("Contacts");
  app.activate();
  delay(0.5);

  const matches = [];
  const seen = new Set();

  if (normalizedField === "name" || normalizedField === "all") {
    const nameMatches = exact
      ? app.people.whose({name: query})()
      : app.people.whose({name: {_contains: query}})();

    for (const person of nameMatches) {
      addUnique(matches, seen, person);
      if (matches.length >= limit) {
        break;
      }
    }
  }

  if ((normalizedField === "org" || normalizedField === "all") && matches.length < limit) {
    const organizationMatches = exact
      ? app.people.whose({organization: query})()
      : app.people.whose({organization: {_contains: query}})();

    for (const person of organizationMatches) {
      addUnique(matches, seen, person);
      if (matches.length >= limit) {
        break;
      }
    }
  }

  const shouldScanDetailFields =
    normalizedField === "phone" ||
    normalizedField === "email" ||
    (normalizedField === "all" && detailLikeQuery);

  if (shouldScanDetailFields && matches.length < limit) {
    const people = app.people();

    for (const person of people) {
      if (matches.length >= limit) {
        break;
      }

      if (seen.has(person.id())) {
        continue;
      }

      let matched = false;

      if (normalizedField === "phone" || normalizedField === "all") {
        try {
          for (const phone of person.phones()) {
            if (matchesValue(phone.value(), query, exact)) {
              matched = true;
              break;
            }
          }
        } catch (error) {}
      }

      if (!matched && (normalizedField === "email" || normalizedField === "all")) {
        try {
          for (const email of person.emails()) {
            if (matchesValue(email.value(), query, exact)) {
              matched = true;
              break;
            }
          }
        } catch (error) {}
      }

      if (matched) {
        addUnique(matches, seen, person);
      }
    }
  }

  return JSON.stringify({
    success: true,
    count: matches.length,
    limit: limit,
    data: matches.map(personEntry)
  }, null, 2);
}
EOF
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

  run_jxa osascript -l JavaScript - "$selector_mode" "$selector" <<'EOF'
function normalizeLabel(label) {
  const raw = String(label || "");
  const known = {
    "_$!<Mobile>!$_": "mobile",
    "_$!<Home>!$_": "home",
    "_$!<Work>!$_": "work",
    "_$!<Main>!$_": "main",
    "_$!<Other>!$_": "other",
    "_$!<HomePage>!$_": "homepage",
    "_$!<School>!$_": "school",
    "_$!<iPhone>!$_": "iphone",
    "Phone": "phone"
  };

  if (Object.prototype.hasOwnProperty.call(known, raw)) {
    return known[raw];
  }

  const tokenMatch = raw.match(/^_\$!<(.*)>!\$_$/);
  if (tokenMatch) {
    return tokenMatch[1].toLowerCase().replace(/\s+/g, "-");
  }

  return raw.toLowerCase().replace(/\s+/g, "-");
}

function personEntry(person) {
  const entry = {
    id: person.id(),
    name: person.name()
  };

  try {
    const firstName = person.firstName();
    if (firstName) {
      entry.firstName = firstName;
    }
  } catch (error) {}

  try {
    const lastName = person.lastName();
    if (lastName) {
      entry.lastName = lastName;
    }
  } catch (error) {}

  try {
    const phones = person.phones();
    if (phones.length > 0) {
      entry.phones = phones.map(phone => ({
        label: normalizeLabel(phone.label()),
        value: phone.value()
      }));
    }
  } catch (error) {}

  try {
    const emails = person.emails();
    if (emails.length > 0) {
      entry.emails = emails.map(email => ({
        label: normalizeLabel(email.label()),
        value: email.value()
      }));
    }
  } catch (error) {}

  try {
    const addresses = person.addresses();
    if (addresses.length > 0) {
      entry.addresses = addresses.map(address => ({
        label: normalizeLabel(address.label()),
        street: address.street() || "",
        city: address.city() || "",
        zip: address.zip() || "",
        country: address.country() || ""
      }));
    }
  } catch (error) {}

  try {
    const organization = person.organization();
    if (organization) {
      entry.organization = organization;
    }
  } catch (error) {}

  try {
    const title = person.jobTitle();
    if (title) {
      entry.jobTitle = title;
    }
  } catch (error) {}

  try {
    const birthday = person.birthDate();
    if (birthday) {
      entry.birthday = birthday.toISOString().split("T")[0];
    }
  } catch (error) {}

  try {
    const note = person.note();
    if (note) {
      entry.note = note;
    }
  } catch (error) {}

  return entry;
}

function findMatches(app, selectorMode, selectorValue) {
  if (selectorMode === "id") {
    return app.people().filter(person => person.id() === selectorValue);
  }

  return app.people.whose({name: selectorValue})();
}

function run(argv) {
  const [selectorMode, selectorValue] = argv;
  const app = Application("Contacts");
  app.activate();
  delay(0.5);

  const matches = findMatches(app, selectorMode, selectorValue);

  if (matches.length === 0) {
    return JSON.stringify({success: false, error: "Contact not found: " + selectorValue});
  }

  return JSON.stringify({
    success: true,
    count: matches.length,
    data: matches.map(personEntry)
  }, null, 2);
}
EOF
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

  run_jxa osascript -l JavaScript - "$group" "$limit" <<'EOF'
function normalizeLabel(label) {
  const raw = String(label || "");
  const known = {
    "_$!<Mobile>!$_": "mobile",
    "_$!<Home>!$_": "home",
    "_$!<Work>!$_": "work",
    "_$!<Main>!$_": "main",
    "_$!<Other>!$_": "other",
    "_$!<HomePage>!$_": "homepage",
    "_$!<School>!$_": "school",
    "_$!<iPhone>!$_": "iphone",
    "Phone": "phone"
  };

  if (Object.prototype.hasOwnProperty.call(known, raw)) {
    return known[raw];
  }

  const tokenMatch = raw.match(/^_\$!<(.*)>!\$_$/);
  if (tokenMatch) {
    return tokenMatch[1].toLowerCase().replace(/\s+/g, "-");
  }

  return raw.toLowerCase().replace(/\s+/g, "-");
}

function personEntry(person) {
  const entry = {
    id: person.id(),
    name: person.name()
  };

  try {
    const phones = person.phones();
    if (phones.length > 0) {
      entry.phones = phones.map(phone => ({
        label: normalizeLabel(phone.label()),
        value: phone.value()
      }));
    }
  } catch (error) {}

  try {
    const emails = person.emails();
    if (emails.length > 0) {
      entry.emails = emails.map(email => ({
        label: normalizeLabel(email.label()),
        value: email.value()
      }));
    }
  } catch (error) {}

  try {
    const organization = person.organization();
    if (organization) {
      entry.organization = organization;
    }
  } catch (error) {}

  return entry;
}

function run(argv) {
  const [groupName, limitArg] = argv;
  const limit = Number(limitArg);

  if (!Number.isInteger(limit) || limit < 1) {
    return JSON.stringify({success: false, error: "Invalid --limit: " + limitArg});
  }

  const app = Application("Contacts");
  app.activate();
  delay(0.5);

  let people;
  if (groupName) {
    const groups = app.groups.whose({name: groupName})();
    if (groups.length === 0) {
      return JSON.stringify({success: false, error: "Group not found: " + groupName});
    }
    people = groups[0].people();
  } else {
    people = app.people();
  }

  const results = [];
  const total = people.length;

  for (let index = 0; index < Math.min(limit, total); index += 1) {
    results.push(personEntry(people[index]));
  }

  return JSON.stringify({
    success: true,
    total: total,
    count: results.length,
    limit: limit,
    data: results
  }, null, 2);
}
EOF
}

cmd_add() {
  local first=""
  local last=""
  local phone=""
  local email=""
  local org=""
  local title=""

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

  [ -z "$first" ] && [ -z "$last" ] && json_error "Usage: contacts.sh add --first <name> --last <name> [--phone <num>] [--email <addr>] [--org <company>] [--title <title>]"

  run_jxa osascript -l JavaScript - "$first" "$last" "$phone" "$email" "$org" "$title" <<'EOF'
function run(argv) {
  const [first, last, phone, email, org, title] = argv;
  const app = Application("Contacts");
  app.activate();
  delay(0.5);

  const props = {};
  if (first) {
    props.firstName = first;
  }
  if (last) {
    props.lastName = last;
  }
  if (org) {
    props.organization = org;
  }
  if (title) {
    props.jobTitle = title;
  }

  const person = app.Person(props);
  app.people.push(person);

  if (phone) {
    person.phones.push(app.Phone({label: "mobile", value: phone}));
  }

  if (email) {
    person.emails.push(app.Email({label: "home", value: email}));
  }

  app.save();

  return JSON.stringify({
    success: true,
    message: "Contact created: " + person.name(),
    id: person.id(),
    name: person.name()
  }, null, 2);
}
EOF
}

cmd_edit() {
  local selector_mode="name"
  local selector=""
  local phone=""
  local email=""
  local org=""
  local title=""

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

  [ -z "$selector" ] && json_error "Usage: contacts.sh edit [--id <contact-id>] <full-name> [--phone <num>] [--email <addr>] [--org <company>] [--title <title>]"
  [ -z "$phone" ] && [ -z "$email" ] && [ -z "$org" ] && [ -z "$title" ] && json_error "Nothing to update. Provide at least one of --phone, --email, --org, --title"

  run_jxa osascript -l JavaScript - "$selector_mode" "$selector" "$phone" "$email" "$org" "$title" <<'EOF'
function findMatch(app, selectorMode, selectorValue) {
  if (selectorMode === "id") {
    const matches = app.people().filter(person => person.id() === selectorValue);
    return matches.length > 0 ? matches[0] : null;
  }

  const matches = app.people.whose({name: selectorValue})();
  return matches.length > 0 ? matches[0] : null;
}

function run(argv) {
  const [selectorMode, selectorValue, phone, email, org, title] = argv;
  const app = Application("Contacts");
  app.activate();
  delay(0.5);

  const person = findMatch(app, selectorMode, selectorValue);
  if (!person) {
    return JSON.stringify({success: false, error: "Contact not found: " + selectorValue});
  }

  const changes = [];

  if (org) {
    person.organization = org;
    changes.push("organization");
  }

  if (title) {
    person.jobTitle = title;
    changes.push("jobTitle");
  }

  if (phone) {
    person.phones.push(app.Phone({label: "mobile", value: phone}));
    changes.push("phone");
  }

  if (email) {
    person.emails.push(app.Email({label: "home", value: email}));
    changes.push("email");
  }

  app.save();

  return JSON.stringify({
    success: true,
    message: "Updated: " + person.name(),
    id: person.id(),
    changes: changes
  }, null, 2);
}
EOF
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

  run_jxa osascript -l JavaScript - "$selector_mode" "$selector" <<'EOF'
function findMatch(app, selectorMode, selectorValue) {
  if (selectorMode === "id") {
    const matches = app.people().filter(person => person.id() === selectorValue);
    return matches.length > 0 ? matches[0] : null;
  }

  const matches = app.people.whose({name: selectorValue})();
  return matches.length > 0 ? matches[0] : null;
}

function run(argv) {
  const [selectorMode, selectorValue] = argv;
  const app = Application("Contacts");
  app.activate();
  delay(0.5);

  const person = findMatch(app, selectorMode, selectorValue);
  if (!person) {
    return JSON.stringify({success: false, error: "Contact not found: " + selectorValue});
  }

  const result = {
    success: true,
    message: "Deleted: " + person.name(),
    id: person.id(),
    name: person.name()
  };

  app.delete(person);
  app.save();

  return JSON.stringify(result, null, 2);
}
EOF
}

cmd_groups() {
  run_jxa osascript -l JavaScript <<'EOF'
function run() {
  const app = Application("Contacts");
  app.activate();
  delay(0.5);

  const groups = app.groups();
  const results = groups.map(group => ({
    name: group.name(),
    count: group.people().length
  }));

  return JSON.stringify({success: true, count: results.length, data: results}, null, 2);
}
EOF
}

cmd_doctor() {
  run_jxa osascript -l JavaScript <<'EOF'
function run() {
  const app = Application("Contacts");
  app.activate();
  delay(0.5);

  try {
    const peopleCount = app.people().length;
    const groupCount = app.groups().length;

    return JSON.stringify({
      success: true,
      data: {
        app: "Contacts",
        automationAccess: true,
        peopleCount: peopleCount,
        groupCount: groupCount
      }
    }, null, 2);
  } catch (error) {
    return JSON.stringify({
      success: false,
      error: "Contacts automation check failed: " + error.message
    });
  }
}
EOF
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
