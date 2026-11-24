# Validation

Static, on the host.

```bash
make lint         # shellcheck on every shell script in the repo
make brew-check   # do the Brewfiles actually describe this machine?
make validate     # both
```

## `make lint`

Covers the scripts in `home/.chezmoiscripts/` and
`home/dot_config/mise/executable_after-install.sh`.
They must stay **free of any warning**, not just free of errors.

shellcheck cannot read a `.tmpl`: the script templates (`SHELL_TEMPLATES` in the
Makefile) are rendered with `chezmoi execute-template` for this machine and
checked on stdin.

`shellcheck` is assumed to be installed: it is in no Brewfile, and the target
fails with the install command if it is missing.

## `make brew-check`

`brew bundle check --no-upgrade --verbose` on `Brewfile.common` and on the
`Brewfile.$MACHINE_TYPE` of the current machine. Unlike lint it **does not
validate the code, but the state of the machine**: it tells you whether the
Brewfiles and what you actually have installed have diverged, in either direction.

## Notes

- `brew --caskroom <cask>` is a valid Homebrew flag, but costs ~700 ms: it resolves
  the cask in Ruby, whereas `brew --prefix` and `brew --caskroom` without arguments
  answer in ~30 ms from the shell wrapper. It must not be used in shell startup paths.
