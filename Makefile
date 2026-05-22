.PHONY: dictionary dictionary-contacts dictionary-standard compile check test test-dictionary test-smoke

dictionary:
	@printf '### Contacts.app\n'
	@sdef /System/Applications/Contacts.app
	@printf '\n### CocoaStandard.sdef\n'
	@cat /System/Library/ScriptingDefinitions/CocoaStandard.sdef

dictionary-contacts:
	@sdef /System/Applications/Contacts.app

dictionary-standard:
	@cat /System/Library/ScriptingDefinitions/CocoaStandard.sdef

compile:
	@set -euo pipefail; \
	find scripts/applescripts -name '*.applescript' -print | while IFS= read -r file; do \
		osacompile -o /tmp/$$(echo "$$file" | tr '/' '_' | sed 's/\.applescript$$/.scpt/') "$$file" || exit 1; \
	done; \
	find scripts/tests scripts/commands -name '*.sh' -print | while IFS= read -r file; do \
		bash -n "$$file" || exit 1; \
	done

check:
	@bash scripts/commands/system/doctor.sh >/dev/null 2>&1 || { echo "check: Contacts.app or Automation not available"; exit 1; }
	@echo "Contacts.app is available"

test: test-dictionary test-smoke

test-dictionary:
	@bash scripts/tests/dictionary_contract.sh

test-smoke:
	@bash scripts/tests/smoke_contacts.sh
