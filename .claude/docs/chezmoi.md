# chezmoi

## Naming convention

- `dot_` prefix → `.` in the target: `dot_config/` → `~/.config/`, `dot_zshrc` → `~/.zshrc`
- `executable_` prefix → sets the executable bit: `dot_config/mise/executable_after-install.sh` → `~/.config/mise/after-install.sh` (executable). The target name does **not** contain the prefix — references in `config.toml` point to `~/.config/mise/after-install.sh`
- `.tmpl` suffix → run through the template engine
- Files without prefixes map literally
- Entries starting with `.` are ignored, except the `.chezmoi*` special files and directories

## Scripts (`home/.chezmoiscripts/`)

- `run_once_` → runs once per rendered content; `run_onchange_` → runs when the rendered content changes; `before_` / `after_` → before / after the dotfiles are written. Same kind: name order, hence the `00-`, `10-`, `20-` prefixes
- A script must be idempotent: chezmoi re-runs it whenever its content changes
- To re-run a script on a file outside it, put the file's hash in the rendered output: `{{ include … | sha256sum }}`
- A Homebrew installed by `00-install-homebrew` is not on chezmoi's `PATH`: the later scripts run `brew shellenv` themselves
- Reset: `chezmoi state delete-bucket --bucket=scriptState` (`run_once_`), `--bucket=entryState` (`run_onchange_`)

## Paths

- `sourceDir` in the config is the **repo root**; `.chezmoiroot` sends chezmoi to `home/`
- In the templates: `.chezmoi.sourceDir` = `home/`, `.chezmoi.workingTree` = repo root (use it to reach `brew/`)

## Commands

- Bootstrap: see `install.md`; from a clone, `chezmoi init --source=<repo> --apply` — NOT just `apply` (`init` is needed to regenerate `~/.config/chezmoi/chezmoi.toml` from the template)
- Re-apply after a pull: `chezmoi apply` (or `chezmoi update`, which pulls first)
- Dry run: `chezmoi apply --dry-run --verbose`
- Test a template: `chezmoi execute-template < home/<file>.tmpl`
