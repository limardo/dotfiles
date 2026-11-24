# Shell scripts under validation.
SHELL_SCRIPTS := home/.chezmoiscripts/run_once_before_00-install-homebrew.sh \
                 home/.chezmoiscripts/run_onchange_after_20-macos-defaults.sh \
                 home/dot_config/mise/executable_after-install.sh \
                 scripts/check_email.sh \
                 scripts/check_templates.sh

# Script templates: shellcheck reads them as rendered by chezmoi for this machine.
SHELL_TEMPLATES := home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl

MACHINE_TYPE ?= $(shell chezmoi execute-template '{{ .machine_type }}' 2>/dev/null || echo work)

.PHONY: lint templates brew-check validate

# ── Validation ────────────────────────────────────────────────────
# Static, on the host, in a couple of seconds.

# Must stay free of any warning, not just free of errors.
lint:
	@command -v shellcheck >/dev/null || { echo "[lint] ✗ shellcheck not installed: brew install shellcheck" >&2; exit 1; }
	@shellcheck $(SHELL_SCRIPTS)
	@for t in $(SHELL_TEMPLATES); do \
	  out="$$(chezmoi execute-template < "$$t")" || exit 1; \
	  printf '%s\n' "$$out" | shellcheck - || { echo "[lint] ✗ in $$t (rendered)" >&2; exit 1; }; \
	done
	@echo "[lint] ✓ shellcheck clean on $(words $(SHELL_SCRIPTS) $(SHELL_TEMPLATES)) scripts"

# Render every template for both machine types and check the output.
templates:
	@scripts/check_templates.sh

# Check that the Brewfiles really describe the state of THIS machine.
brew-check:
	@brew bundle check --file=brew/Brewfile.common --no-upgrade --verbose
	@brew bundle check --file=brew/Brewfile.$(MACHINE_TYPE) --no-upgrade --verbose

validate: lint templates brew-check
