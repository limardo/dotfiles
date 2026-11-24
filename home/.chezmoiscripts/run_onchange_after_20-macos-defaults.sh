#!/usr/bin/env bash
# Applies the macOS system defaults. Run by chezmoi after the dotfiles, and
# again whenever this file changes; idempotent, safe to re-run on its own.

set -euo pipefail

# ── Finder ────────────────────────────────────────────────────
# Hide file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool false
# Show the path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true
# Hide the status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool false
# Use column view by default in Finder
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
# Keep folders on top when sorting by name
defaults write com.apple.finder "_FXSortFoldersFirst" -bool true

# ── Desktop ────────────────────────────────────────────────────
# Keep folders on top when sorting
defaults write com.apple.finder "_FXSortFoldersFirstOnDesktop" -bool true

# Restart Finder so it picks up the new values. Failure is ignored on purpose:
# killall exits non-zero when Finder is not running, and then there is nothing
# to restart.
killall Finder 2>/dev/null || true

echo "macOS defaults applied. Some changes require a logout/restart."
