.PHONY: dictionary-contacts check compile test test-dictionary test-smoke

dictionary-contacts:
	@sdef /System/Applications/Contacts.app

check:
	@bash scripts/commands/system/doctor.sh >/dev/null 2>&1 || { echo "check: Contacts.app or Automation not available"; exit 1; }
	@echo "Contacts.app is available"

compile:
	@set -euo pipefail; \
	find scripts/applescripts -name '*.applescript' -print | while IFS= read -r file; do \
		osacompile -o /tmp/$$(echo "$$file" | tr '/' '_' | sed 's/\.applescript$$/.scpt/') "$$file"; \
	done

test: test-dictionary test-smoke

test-dictionary:
	@bash tests/dictionary_contract.sh

test-smoke:
	@bash tests/smoke_contacts.sh
