# Validation

Static, on the host.

```bash
make lint         # shellcheck on every shell script in the repo
make templates    # render every template for both machine types and check it
make brew-check   # do the Brewfiles actually describe this machine?
make validate     # all three
```

## `make lint`

Covers the scripts in `home/.chezmoiscripts/`, `scripts/` and
`home/dot_config/mise/executable_after-install.sh`.
They must stay **free of any warning**, not just free of errors.

CI (`.github/workflows/lint.yml`) runs the same `make lint` on every push to
`main` and every PR, once per machine type, with a throwaway chezmoi config.

shellcheck cannot read a `.tmpl`: the script templates (`SHELL_TEMPLATES` in the
Makefile) are rendered with `chezmoi execute-template` for this machine and
checked on stdin.

`shellcheck` is assumed to be installed: it is in no Brewfile, and the target
fails with the install command if it is missing.

## `make templates`

`scripts/check_templates.sh` runs `chezmoi init` against a throwaway config once
per machine type (so `home/.chezmoi.toml.tmpl` is checked too), renders every
`home/**/*.tmpl` and checks the output: shellcheck for `*.sh.tmpl`, `zsh -n`
for `dot_zshrc.tmpl`, `git config --list` for `dot_gitconfig.tmpl`. Any other
template is checked by rendering alone; add a `case` branch for a new format.

## pre-commit

`.pre-commit-config.yaml` runs before each commit: gitleaks, shfmt, actionlint,
taplo, `make lint`, `scripts/check_templates.sh`, and
`scripts/check_email.sh` (fails if a file contains this machine's
`git config user.email`: gitleaks does not treat an email as a secret). On the
`commit-msg` hook, conventional-pre-commit enforces Conventional Commits.

Enable once per clone with `pre-commit install`; run everything with
`pre-commit run --all-files`. Hook repos are pinned by commit SHA:
update with `pre-commit autoupdate --freeze`.

## `make brew-check`

`brew bundle check --no-upgrade --verbose` on `Brewfile.common` and on the
`Brewfile.$MACHINE_TYPE` of the current machine. Unlike lint it **does not
validate the code, but the state of the machine**: it tells you whether the
Brewfiles and what you actually have installed have diverged, in either direction.

## Notes

- `brew --caskroom <cask>` is a valid Homebrew flag, but costs ~700 ms: it resolves
  the cask in Ruby, whereas `brew --prefix` and `brew --caskroom` without arguments
  answer in ~30 ms from the shell wrapper. It must not be used in shell startup paths.
