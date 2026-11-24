#!/usr/bin/env bash
# Installs Homebrew on a new machine. Run by chezmoi before the packages
# script, once; a no-op where brew is already installed.
set -euo pipefail

readonly HOMEBREW_INSTALL_URL='https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh'

log() { echo "[homebrew] $*"; }
ok() { echo "[homebrew] ✓ $*"; }
fail() {
  echo "[homebrew] ✗ $*" >&2
  exit 1
}

if [[ -x /opt/homebrew/bin/brew ]] || command -v brew &>/dev/null; then
  ok "Homebrew already present"
  exit 0
fi

log "Installing Homebrew..."
# Downloaded into a variable first: inside `bash -c "$(curl ...)"` a failed
# download becomes an empty script that exits 0, and set -e never sees it.
installer="$(curl -fsSL "${HOMEBREW_INSTALL_URL}")" \
  || fail "Homebrew installer download failed"
/bin/bash -c "${installer}"
ok "Homebrew installed"
