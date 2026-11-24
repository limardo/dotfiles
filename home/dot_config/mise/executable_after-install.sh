#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
# ~/.config/mise/after-install.sh
# Called by mise after every `mise install` / `mise use`.
# Regenerates the static completions of the tools MANAGED BY MISE and
# invalidates the compinit dump so the next shell sees them right away.
#
# It does not touch tools installed by brew or by casks (mise, gh, docker…):
# those install their own completions in
# `$(brew --prefix)/share/zsh/site-functions`, often as symlinks
# into the Cellar. Writing over them would corrupt someone else's files.
# ════════════════════════════════════════════════════════════════

set -euo pipefail

# Same directory declared in the fpath by ~/.zshrc, and not managed
# by brew: no collisions with the Cellar symlinks.
COMP_DIR="${COMP_DIR:-${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/completions}"
readonly COMP_DIR

#######################################
# Generates one zsh completion file. The output goes to a temp file and is
# promoted only if it is a real autoloadable completion function: without
# the `#compdef` line compinit never binds it to the command and the file
# stays inert.
# Globals:
#   COMP_DIR
# Arguments:
#   Completion file name (e.g. _kubectl), then the command that prints the
#   completion script, with its arguments.
# Outputs:
#   Writes a warning to STDERR when generation fails or is rejected.
# Returns:
#   0, also when the command is missing or fails: one broken tool must not
#   stop the others.
#######################################
_gen() {
  local name="$1"
  shift
  command -v "$1" &>/dev/null || return 0

  local tmp
  tmp="$(mktemp)"
  if ! "$@" >"${tmp}" 2>/dev/null || [[ ! -s "${tmp}" ]]; then
    rm -f "${tmp}"
    echo "⚠️  ${name}: generation failed" >&2
    return 0
  fi

  # read fails on a last line without a newline, but has set the variable.
  local first_line=""
  IFS= read -r first_line <"${tmp}" || true
  if [[ "${first_line}" != '#compdef'* ]]; then
    rm -f "${tmp}"
    echo "⚠️  ${name}: output without a '#compdef' line, ignored" >&2
    return 0
  fi

  mv "${tmp}" "${COMP_DIR}/${name}"
  chmod 644 "${COMP_DIR}/${name}"
}

mkdir -p "${COMP_DIR}"

# ── mise ─────────────────────────────────────────────────────────
_gen _usage usage --completions zsh

# ── python ───────────────────────────────────────────────────────
_gen _uv uv generate-shell-completion zsh
_gen _uvx uvx --generate-shell-completion zsh

# ── kubernetes ───────────────────────────────────────────────────
_gen _kubectl kubectl completion zsh
_gen _helm helm completion zsh
_gen _k9s k9s completion zsh

# ── rust ─────────────────────────────────────────────────────────
_gen _rustup rustup completions zsh
_gen _cargo rustup completions zsh cargo

# ── terraform ────────────────────────────────────────────────────
# terraform, terragrunt and tofu have no subcommand that emits a
# zsh script: they use the bash `complete -C` protocol, enabled in
# ~/.zshrc. Only terraform-docs is a regular generator.
_gen _terraform-docs terraform-docs completion zsh

# ── node ─────────────────────────────────────────────────────────
_gen _pnpm pnpm completion zsh
_gen _bun bun completions

# ── moonrepo ─────────────────────────────────────────────────────
_gen _moon moon completions --shell zsh

# ── gitlab ───────────────────────────────────────────────────────
_gen _glab glab completion -s zsh

# ── Invalidate the compinit dump ─────────────────────────────────
# The next shell that opens will re-read everything from scratch.
rm -f "${ZDOTDIR:-${HOME}}/.zcompdump"

echo "✅ mise after-install: completions updated in ${COMP_DIR}"
