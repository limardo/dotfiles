# dotfiles

My macOS setup, managed with [chezmoi](https://www.chezmoi.io/). One command
takes a fresh Mac to a working machine: Homebrew, apps, CLI tools, shell,
dotfiles and system defaults.

A single repo serves two profiles, **`personal`** and **`work`**: they share
the base and differ in the apps installed and in a few shell settings.

## What's inside

| Area           | Tools                                                                                                                                                                               |
|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Shell          | zsh in vi mode, [Sheldon](https://sheldon.cli.rs/) plugins, [Starship](https://starship.rs/) prompt, [Atuin](https://atuin.sh/) history, [zoxide](https://github.com/ajeetdsouza/zoxide), fzf, direnv |
| Terminal       | [Ghostty](https://ghostty.org/), [tmux](https://github.com/tmux/tmux)                                                                                                               |
| Git            | [delta](https://github.com/dandavison/delta) side-by-side diffs, rebase on pull, diff3 conflicts                                                                                    |
| CLI            | bat, eza, fd, ripgrep, jq, yq, btop                                                                                                                                                 |
| Runtimes       | [mise](https://mise.jdx.dev/): Go, Node, Java, Python/uv, Ruby, Rust, Terraform/OpenTofu, kubectl, helm…                                                                            |
| macOS          | Finder defaults: path bar, column view, folders first                                                                                                                               |

The `work` profile adds cloud CLIs (AWS, Azure, gcloud), IDEs and work apps,
plus `AWS_PROFILE`/`KUBECONFIG` handling and the `awsp` profile switcher.
The `personal` profile adds media and personal apps. Exact lists are in
[`brew/`](brew/).

## Prerequisites

Everything else, Homebrew included, is installed by the setup itself. Before
running it you need:

- **macOS** on Apple Silicon or Intel, with an **administrator account**:
  Homebrew asks for your password (`sudo`) while installing.
- **Xcode Command Line Tools**, which provide `git`:

  ```bash
  xcode-select --install
  ```

  Install them first: chezmoi clones the repo with git before Homebrew runs.
  On a fresh Mac `/usr/bin/git` is only a placeholder that opens the installer
  dialog, and the clone fails.
- **An internet connection**: Homebrew, packages and runtimes are downloaded.

`curl` and `/bin/bash`, used by the install command and the setup scripts,
ship with macOS.

After the install, for SSH: the [Bitwarden](https://bitwarden.com/) desktop
app (installed by the setup) with its SSH agent turned on. See
[SSH keys](#ssh-keys).

## Install

On a fresh Mac, in Terminal:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$(mktemp -d)" init --apply limardo/dotfiles
```

This command also downloads chezmoi into a temporary directory, so there is
no need to install it first; Homebrew installs the permanent one later. If you
already have chezmoi, `chezmoi init --apply limardo/dotfiles` is enough.

chezmoi asks two questions, then does the rest:

1. **Machine type**: `personal` or `work`
2. **Git email** for this machine

Both answers are stored in `~/.config/chezmoi/chezmoi.toml`, outside the repo,
and are not asked again. Then it installs Homebrew, installs the packages of
`Brewfile.common` and of your profile, writes the dotfiles and applies the
macOS defaults. Restart the shell when it is done.

### Keep the repo where you want it

By default the repo is cloned into `~/.local/share/chezmoi`. To keep it
somewhere else, clone it first:

```bash
git clone https://github.com/limardo/dotfiles.git ~/dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$(mktemp -d)" init --apply --source ~/dotfiles
```

### Without prompts

For scripted setups, give the answers on the command line:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$(mktemp -d)" init --apply \
  --promptChoice machine_type=work \
  --promptString git_email=you@example.com \
  limardo/dotfiles
```

## Day to day

`chezmoi cd` opens a shell in the repo, wherever it is.

| I want to…                                  | Command                                              |
|---------------------------------------------|------------------------------------------------------|
| See what would change                       | `chezmoi diff`                                       |
| Apply the repo to `$HOME`                   | `chezmoi apply`                                      |
| Pull the latest changes and apply them      | `chezmoi update`                                     |
| Edit a dotfile                              | `chezmoi edit --apply ~/.zshrc`                      |
| Keep an edit I made directly in `$HOME`     | `chezmoi re-add ~/.tmux.conf`                        |
| Start managing a new file                   | `chezmoi add ~/.config/foo/config.toml`              |
| Same, with per-profile differences          | `chezmoi add --template ~/.config/foo/config.toml`   |
| Check the values the templates see          | `chezmoi data`                                       |

`chezmoi edit` and `chezmoi add` change files in the repo: commit and push
them with git as usual.

`re-add` skips templates (`.zshrc`, `.gitconfig`): change those with
`chezmoi edit`, or your edit is overwritten on the next apply.

### Packages

Add or remove a line in [`brew/Brewfile.common`](brew/Brewfile.common) (every
machine) or in `brew/Brewfile.work` / `brew/Brewfile.personal`, then run
`chezmoi apply`. The install script runs again only when one of those
Brewfiles changed.

Removing a line does not uninstall the package: run `brew uninstall` yourself.

### Runtimes

Language runtimes and their CLIs come from mise, not Homebrew. Edit
[`home/dot_config/mise/config.toml`](home/dot_config/mise/config.toml), then:

```bash
chezmoi apply && mise install
```

After each install mise regenerates the zsh completions of the tools it
manages.

### macOS defaults

Edit
[`home/.chezmoiscripts/run_onchange_after_20-macos-defaults.sh`](home/.chezmoiscripts/run_onchange_after_20-macos-defaults.sh)
and run `chezmoi apply`: the script runs again because its content changed.

### Switching profile

Change `machine_type` in `~/.config/chezmoi/chezmoi.toml`, then run
`chezmoi apply`. Packages of the old profile stay installed.

## Shell cheat sheet

| Key / command          | Does                                                |
|------------------------|-----------------------------------------------------|
| `Ctrl-O`               | Searchable list of every key bound in the shell     |
| `ll`, `lt`             | Detailed list, tree (eza)                           |
| `ta`, `tl`, `tn`, `tk` | tmux attach, list, new, kill session                |
| `brewup`               | Update and upgrade everything in Homebrew, clean up |
| `port 8080`            | What is listening on a port                         |
| `awsp`                 | Pick an AWS profile with fzf (`work` only)          |

`cat`, `grep`, `find`, `diff` and `top` are aliased to bat, ripgrep, fd, delta
and btop.

## How it works

```text
.
├── .chezmoiroot            # "home": chezmoi reads the dotfiles from home/
├── brew/                   # Brewfile.common, Brewfile.work, Brewfile.personal
└── home/                   # mirrors $HOME, in chezmoi's naming
    ├── .chezmoi.toml.tmpl  # the two setup questions
    ├── .chezmoiscripts/    # run by chezmoi apply, in this order:
    │   ├── run_once_before_00-install-homebrew.sh
    │   ├── run_onchange_before_10-install-packages.sh.tmpl
    │   └── run_onchange_after_20-macos-defaults.sh
    ├── dot_zshrc.tmpl      # → ~/.zshrc
    ├── dot_gitconfig.tmpl  # → ~/.gitconfig
    └── dot_config/         # → ~/.config
```

- **File names** follow
  [chezmoi's conventions](https://www.chezmoi.io/reference/source-state-attributes/):
  `dot_` becomes `.`, `executable_` sets the executable bit, `.tmpl` files are
  templates.
- **Profiles** are template branches: `{{ if eq .machine_type "work" }}`.
- **Scripts**: `run_once_` runs once, `run_onchange_` runs again when its
  content changes. The packages script embeds a hash of the Brewfiles, so
  editing a Brewfile counts as a change.
- **No personal data in the repo**: the machine type and the git email live
  only in the local chezmoi config.

To re-run a script without changing it:

```bash
chezmoi state delete-bucket --bucket=entryState   # run_onchange_ scripts
chezmoi state delete-bucket --bucket=scriptState  # run_once_ scripts
```

## SSH keys

`SSH_AUTH_SOCK` points to the [Bitwarden](https://bitwarden.com/) SSH agent
(`~/.bitwarden-ssh-agent.sock`): SSH keys live in the vault, not in `~/.ssh`.
Turn on the SSH agent in the Bitwarden desktop app, or SSH will find no keys.

## Development

```bash
make lint         # shellcheck on every script (needs: brew install shellcheck)
make brew-check   # do the Brewfiles match what is installed on this machine?
make validate     # both
```

## License

[MIT](LICENSE)
