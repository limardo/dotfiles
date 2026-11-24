# Shell scripts

Bash/sh scripts follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html),
with the repo-specific deviations listed first. They win over the guide.

## Repo deviations

- **Target bash 3.2.** No Brewfile installs bash, so `#!/usr/bin/env bash` resolves to
  macOS's `/bin/bash` 3.2 — and `install.sh` runs before Homebrew exists anyway.
  Not available: `readarray`/`mapfile`, `declare -A`, `${var,,}`/`${var^^}`, `&>>`,
  negative array indices. Under `set -u`, `"${arr[@]}"` on an **empty** array is an
  unbound-variable error before bash 4.4: guard it (`${arr[@]+"${arr[@]}"}`).
- **Shebang:** `#!/usr/bin/env bash`, followed by `set -euo pipefail` (or `set -uo pipefail`
  with a comment explaining why `-e` is off, as in `tests/guest-bootstrap.sh`).
- **Output helpers:** keep each script's existing `log` / `ok` / `fail` helpers with their
  `[prefix]` instead of the guide's timestamped `err()`. Errors still go to STDERR.
- **Length:** the guide's "rewrite past 100 lines" is not applied — this repo is shell by
  design. Keep scripts small by splitting into focused functions or sourced libraries.
- **`main`:** not required for linear scripts (`install.sh`, `macos/defaults.sh`); required
  for new scripts that define functions and then run logic.
- **Existing code:** when editing a file, match its style; apply these rules to the lines
  you write. Do not reformat untouched code.
- `make lint` must stay free of shellcheck warnings. Disable a check only inline, with
  the reason: `# shellcheck disable=SC2016  # expanded in the VM, not on the host`.

## Files

- Executables: `.sh` or no extension (no extension for things on the `PATH`, e.g.
  `tests/bin/bw`). Libraries: `.sh`, not executable, sourced.
- File names: lowercase, words joined by `_` or nothing (`make_template`, not `make-template`).
  Exception: names imposed by tools, e.g. chezmoi's `executable_after-install.sh`.
- No SUID/SGID. Use `sudo` when elevation is needed.

## Comments

- A header comment right after the shebang: what the script does, and where it runs
  (host or VM) when it is not obvious.
- Every function that is not both short and obvious gets a header comment; every
  function in a sourced library gets one regardless:
  ```bash
  #######################################
  # One-line description.
  # Globals:
  #   VM_NAME
  # Arguments:
  #   Path to the public key.
  # Outputs:
  #   Writes progress to STDOUT.
  # Returns:
  #   0 on success, non-zero if the copy fails.
  #######################################
  ```
  Omit sections that do not apply.
- Implementation comments explain *why* for tricky or non-obvious code, not *what*.
- TODOs: `# TODO(name): ...`.

## Formatting

- 2-space indent, no tabs (except the body of a `<<-` heredoc). Blank lines between blocks.
- Max 80 columns. Long strings go into a heredoc or embedded newlines; an unsplittable
  path/URL may exceed it, on its own line or in a variable.
- Pipelines that don't fit on one line: one segment per line, continuation lines start
  with `|` (or `&&` / `||`) indented 2 spaces. A comment goes above the whole pipeline.
- `; then` / `; do` on the same line as `if` / `for` / `while`; `else`, `fi`, `done` on
  their own lines, aligned with the opening keyword.
- `for arg in "$@"; do`, written out explicitly.
- `case`: alternatives indented 2 spaces, bodies another 2. One-liners as `a) cmd ;;`;
  longer ones with pattern, body and `;;` on separate lines. No `(` before patterns,
  no `;&` / `;;&`.

## Variables and quoting

- Prefer `"${var}"` over `"$var"`. Do not brace specials and positionals (`$1`, `$#`,
  `$?`, `$@`) unless needed (`${10}`). Braces are not quoting.
- Always quote strings containing variables, command substitutions, spaces or
  metacharacters — command substitutions too: `n="$(count)"`. Don't quote literal integers.
- `"$@"` to pass arguments; `$*` only to join into a message.
- Single quotes for literals, double quotes when expanding.
- Lists — especially command-line flags — go in arrays, expanded as `"${flags[@]}"`
  (see the `SSH_OPTS` array in `tests/lib/vm.sh`). Never a space-separated string,
  never `arr=($(cmd))`.

## Naming

- Functions and variables: `lower_snake_case`. Functions as `name() {`, no `function`
  keyword. Library functions may use a `pkg::name` namespace.
- Constants and exported variables: `UPPER_SNAKE_CASE`, at the top of the file, made
  `readonly` as soon as they are set.
- Loop variables are named after what they iterate: `for repo in "${repos[@]}"`.
- Function-local variables are `local`. Declaration and command-substitution
  assignment on separate lines, or `$?` is lost:
  ```bash
  local ip
  ip="$(vm_ip)"
  ```

## Layout

- Order: shebang, header, `set`, sourced files, constants, functions, then code.
  No executable code between functions.
- When `main` is used, it is the last function and the last line is `main "$@"`.

## Features

- `$(cmd)`, never backticks.
- `[[ ... ]]`, never `[ ... ]` or `test`. `==` for equality; regex RHS of `=~` unquoted.
- Strings: `[[ -z "${x}" ]]` / `[[ -n "${x}" ]]`; no `"${x}X" == "fooX"` tricks.
- Numbers: `(( x > 3 ))` or `-gt` / `-lt`; never `<` / `>` inside `[[ ]]` (lexicographic).
- Arithmetic: `(( ... ))` and `$(( ... ))`, no `$` on names inside them; never `let`,
  `expr`, `$[ ]`. Under `set -e`, `(( i++ ))` with `i=0` exits the script on
  bash ≥ 4.1 (3.2 lets it pass, so it breaks only on a newer bash): use
  `i=$(( i + 1 ))`.
- Globs: `./*`, not `*` (file names may start with `-`).
- No `eval`. Exception: `eval "$(brew shellenv)"` and similar tool-provided init
  snippets.
- No aliases in scripts: use functions.
- Don't pipe into `while` (it runs in a subshell): use `while read -r line; do ...; done < <(cmd)`.
- Prefer builtins and parameter expansion (`${s/#foo/bar}`, `${s%%:*}`, `=~` with
  `BASH_REMATCH`) over `sed` / `expr` / `echo | ...` for in-memory strings.

## Errors

- Check return values and fail with an informative message on STDERR:
  `cmd || fail "cmd failed"` or `if ! cmd; then ...; fi`.
- For pipelines, read `PIPESTATUS` immediately after the pipe (copy it into an array
  if you need more than one element): any later command overwrites it.
