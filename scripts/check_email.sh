#!/usr/bin/env bash
# Fails if one of the given files contains this machine's git user.email: the
# repo must stay publishable without personal data, and gitleaks does not
# treat an email as a secret. Runs on the host, called by pre-commit with the
# files to check.

set -euo pipefail

email="$(git config user.email || true)"
if [[ -z "${email}" || $# -eq 0 ]]; then
  exit 0
fi

if grep -nIiF -- "${email}" "$@"; then
  echo "[email] ✗ git user.email found in the files above" >&2
  exit 1
fi
