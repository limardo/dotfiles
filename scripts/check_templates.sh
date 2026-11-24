#!/usr/bin/env bash
# Renders every chezmoi template once per machine type, against a throwaway
# config, and checks each output with the tool that understands its format.
# Runs on the host, from the repo root (make templates, pre-commit).

set -euo pipefail

readonly MACHINE_TYPES=(personal work)

ok() { echo "[templates] ✓ $*"; }
fail() {
  echo "[templates] ✗ $*" >&2
  exit 1
}

#######################################
# Checks one rendered template. A template with no checker is covered by the
# rendering alone.
# Arguments:
#   Template path, for the error message and to pick the checker.
#   Path of the rendered output.
# Returns:
#   0 if the output is valid, non-zero otherwise.
#######################################
check_rendered() {
  local template="$1"
  local rendered="$2"

  case "${template}" in
    *.sh.tmpl) shellcheck "${rendered}" ;;
    */dot_zshrc.tmpl) zsh -n "${rendered}" ;;
    */dot_gitconfig.tmpl) git config --file "${rendered}" --list >/dev/null ;;
    *) ;;
  esac
}

#######################################
# Renders and checks every template for one machine type.
# Globals:
#   tmp_dir
# Arguments:
#   Machine type.
# Outputs:
#   Writes progress to STDOUT, failures to STDERR.
#######################################
check_machine_type() {
  local machine_type="$1"
  local cz=(chezmoi --config "${tmp_dir}/${machine_type}.toml"
    --persistent-state "${tmp_dir}/${machine_type}.boltdb")
  local rendered="${tmp_dir}/rendered"
  local template
  local count=0

  # .chezmoi.toml.tmpl is rendered here, by init: a broken one fails now.
  "${cz[@]}" init --source=. \
    --promptChoice "machine_type=${machine_type}" \
    --promptString git_email=ci@example.invalid \
    || fail "chezmoi init (${machine_type})"

  while IFS= read -r template; do
    "${cz[@]}" execute-template <"${template}" >"${rendered}" \
      || fail "${template} does not render (${machine_type})"
    check_rendered "${template}" "${rendered}" \
      || fail "${template} rendered is invalid (${machine_type})"
    count=$((count + 1))
  done < <(git ls-files 'home/*.tmpl' ':!:home/.chezmoi.toml.tmpl')

  ok "${count} templates valid for ${machine_type}"
}

main() {
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' EXIT

  local machine_type
  for machine_type in "${MACHINE_TYPES[@]}"; do
    check_machine_type "${machine_type}"
  done
}

main "$@"
