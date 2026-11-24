#!/usr/bin/env bash
# Backs up ~/.ssh, ~/.aws and ~/.kube into a plain tar.gz, to carry them by
# hand to a new machine, and restores them there. Runs on the host, on demand:
# not called by chezmoi. The archive is NOT encrypted: it holds private keys
# and credentials, so it is written with mode 600 and must not be shared.
#
#   secrets_backup.sh backup [dir]     write the archive into dir (~/Backups)
#   secrets_backup.sh restore <file>   extract an archive into ~

set -euo pipefail

readonly DIRS=(.ssh .aws .kube)
readonly DEFAULT_DEST="${HOME}/Backups"
# Caches, sockets and editor droppings: rebuilt by the tools, or not archivable.
readonly EXCLUDES=(
  --exclude '.DS_Store'
  --exclude '.ssh/agent'
  --exclude '.ssh/known_hosts.old'
  --exclude '.aws/cli/cache'
  --exclude '.aws/sso/cache'
  --exclude '.kube/cache'
)

log() { echo "[secrets-backup] $*"; }
ok() { echo "[secrets-backup] ✓ $*"; }
fail() {
  echo "[secrets-backup] ✗ $*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage:
  $(basename "$0") backup [dir]     archive ~/.ssh ~/.aws ~/.kube into dir
                                    (default: ${DEFAULT_DEST})
  $(basename "$0") restore <file>   extract an archive into ${HOME}
EOF
}

#######################################
# Writes the archive of the directories that exist in $HOME.
# Globals:
#   DIRS, DEFAULT_DEST, EXCLUDES, HOME
# Arguments:
#   Destination directory (optional).
# Outputs:
#   Writes progress and the archive path to STDOUT.
#######################################
backup() {
  local dest="${1:-${DEFAULT_DEST}}"
  local present=()
  local dir

  for dir in "${DIRS[@]}"; do
    if [[ -d "${HOME}/${dir}" ]]; then
      present+=("${dir}")
    else
      log "${HOME}/${dir} not found, skipped"
    fi
  done
  ((${#present[@]} > 0)) || fail "nothing to back up"

  mkdir -p "${dest}" || fail "cannot create ${dest}"
  local archive
  archive="${dest}/secrets-$(date +%Y%m%d-%H%M%S).tar.gz"

  # umask before tar: the file is never readable by others, not even briefly.
  (
    umask 077
    tar -czf "${archive}" -C "${HOME}" "${EXCLUDES[@]}" "${present[@]}"
  ) || fail "tar failed, ${archive} may be incomplete"

  ok "${archive} ($(du -h "${archive}" | cut -f1 | tr -d ' '))"
  log "not encrypted: keep it off shared folders and delete it once restored"
}

#######################################
# Extracts an archive made by backup() into $HOME, after a confirmation when
# one of the directories already exists. Files with the same name are
# overwritten; other files are left alone.
# Globals:
#   DIRS, HOME
# Arguments:
#   Path of the archive.
# Outputs:
#   Writes progress to STDOUT, the prompt to STDERR.
#######################################
restore() {
  local archive="${1:-}"
  [[ -n "${archive}" ]] || fail "restore needs the archive path"
  [[ -f "${archive}" ]] || fail "${archive} not found"

  # Only .ssh/.aws/.kube entries: an archive from elsewhere must not be able to
  # write anywhere else under $HOME (or outside it, through ../).
  local entry
  while IFS= read -r entry; do
    if [[ ! "${entry}" =~ ^\.(ssh|aws|kube)(/|$) ]] \
      || [[ "${entry}" =~ (^|/)\.\.(/|$) ]]; then
      fail "unexpected entry in archive: ${entry}"
    fi
  done < <(tar -tzf "${archive}")

  local existing=()
  local dir
  for dir in "${DIRS[@]}"; do
    if [[ -e "${HOME}/${dir}" ]]; then
      existing+=("${HOME}/${dir}")
    fi
  done
  if ((${#existing[@]} > 0)); then
    local prompt="${existing[*]} already exist. Overwrite same-named files?"
    local answer
    read -r -p "${prompt} [y/N] " answer
    [[ "${answer}" == [yY] ]] || fail "aborted, nothing changed"
  fi

  tar -xzpf "${archive}" -C "${HOME}" || fail "extraction failed"
  for dir in "${DIRS[@]}"; do
    if [[ -d "${HOME}/${dir}" ]]; then
      chmod 700 "${HOME}/${dir}"
    fi
  done
  ok "restored into ${HOME}"
}

main() {
  case "${1:-}" in
    backup)
      shift
      backup "$@"
      ;;
    restore)
      shift
      restore "$@"
      ;;
    -h | --help)
      usage
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
