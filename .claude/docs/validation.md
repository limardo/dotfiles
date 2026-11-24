# Validation

Static, on the host, through pre-commit:

```bash
pre-commit install          # once per clone
pre-commit run --all-files  # whole repo
```

`.pre-commit-config.yaml` runs before each commit: gitleaks, shfmt, shellcheck,
actionlint, taplo, `scripts/check_templates.sh` and `scripts/check_email.sh`.
On the `commit-msg` hook, conventional-pre-commit enforces Conventional Commits.
Hook repos are pinned by commit SHA: update with `pre-commit autoupdate --freeze`.

CI (`.github/workflows/lint.yml`) runs `pre-commit run --all-files` on every
push to `main` and every PR.

## shellcheck

Every shell script must stay **free of any warning**, not just free of errors.
zsh files are excluded: shellcheck does not support zsh.

## Templates

shellcheck cannot read a `.tmpl`. `scripts/check_templates.sh` runs
`chezmoi init` against a throwaway config once per machine type (so
`home/.chezmoi.toml.tmpl` is checked too), renders every `home/**/*.tmpl` and
checks the output: shellcheck for `*.sh.tmpl`, `zsh -n` for `dot_zshrc.tmpl`,
`git config --list` for `dot_gitconfig.tmpl`. Any other template is checked by
rendering alone; add a `case` branch for a new format. It needs `chezmoi`,
`shellcheck` and `zsh` on the `PATH`.

## taplo

Run with `--no-schema` (the default catalog fails to load), but a file's own
`"$schema"` is still applied: `starship.toml` is validated against
starship.rs, which needs network.

## No personal email

`scripts/check_email.sh` fails if a file contains this machine's
`git config user.email`: gitleaks does not treat an email as a secret.

## Brewfiles vs this machine

Not a pre-commit hook: it checks the state of the machine, not the code.
It tells you whether the Brewfiles and what is installed have diverged:

```bash
brew bundle check --file=brew/Brewfile.common --no-upgrade --verbose
brew bundle check --file=brew/Brewfile.work --no-upgrade --verbose
```

## Notes

- `brew --caskroom <cask>` is a valid Homebrew flag, but costs ~700 ms: it resolves
  the cask in Ruby, whereas `brew --prefix` and `brew --caskroom` without arguments
  answer in ~30 ms from the shell wrapper. It must not be used in shell startup paths.
