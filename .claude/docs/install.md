# Install

There is no install script: a new machine is bootstrapped with the chezmoi CLI alone.

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$(mktemp -d)" init --apply limardo/dotfiles
# or, from an existing clone:
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$(mktemp -d)" init --apply --source ~/dotfiles
```

`-b` puts the bootstrap chezmoi in a temporary directory: `Brewfile.common` installs the permanent one. Everything else happens inside chezmoi, in this order: prompts for `machine_type` and `git_email` → Homebrew → Brewfile.common + Brewfile.<machine_type> → dotfiles → macOS defaults.

Bitwarden is not needed to install: no template reads from the vault. When one does, `bw` must be installed by a `hooks.read-source-state.pre` hook, because templates are rendered before the `before_` scripts run.

`SSH_AUTH_SOCK` points to `~/.bitwarden-ssh-agent.sock`: SSH keys come from the Bitwarden desktop app's agent, not from `~/.ssh`.
