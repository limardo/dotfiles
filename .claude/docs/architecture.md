# Layout and machine identity

macOS dotfiles managed with chezmoi. A single codebase serves two machine profiles: `personal` and `work`.

## Layout

- `.chezmoiroot` — contains `home`: chezmoi reads the source state from `home/`, not from the repo root
- `home/` — chezmoi source state (mirrors `$HOME`)
- `home/.chezmoiscripts/` — scripts run by `chezmoi apply`, in name order:
  - `run_once_before_00-install-homebrew.sh` — Homebrew, if missing
  - `run_onchange_before_10-install-packages.sh.tmpl` — `brew bundle` on `Brewfile.common` + `Brewfile.<machine_type>`; re-runs when either changes (their hashes are in the rendered script)
  - `run_onchange_after_20-macos-defaults.sh` — macOS system defaults (idempotent); re-runs when the file changes
- `home/dot_claude/` — Claude Code: global rules, own skills. `settings.json` is a `modify_` template (`chezmoi:modify-template`): Claude Code rewrites that file itself, so the repo merges only its own keys into it and keeps the rest (`autoMode` and `statusLine` are machine-specific and stay out; `statusline.sh` is not versioned). A key removed from the template is not removed from the machine. Not a `.tmpl`, so `scripts/check_templates.sh` does not render it: check with `chezmoi cat ~/.claude/settings.json`
- `scripts/secrets_backup.sh` — `backup [dir]` / `restore <file>`: a plain, unencrypted `tar.gz` of `~/.ssh`, `~/.aws`, `~/.kube`, carried by hand to a new machine. Run on demand, never by chezmoi. These directories are deliberately not managed by chezmoi: credentials and client names stay out of the public repo, in any form
- `brew/` — `Brewfile.common` + `Brewfile.work` / `Brewfile.personal`, outside the source state: the packages script reads them through `.chezmoi.workingTree`
- `home/.chezmoiexternal.toml.tmpl` — clones tpm into `~/.tmux/plugins/tpm` (`git-repo`, pulled weekly); the plugins listed in `dot_tmux.conf` are installed by tpm itself (`prefix + I`), not by chezmoi. It also downloads `~/.claude/rules/karpathy.md` (`file`, from `multica-ai/andrej-karpathy-skills` on `main`, refreshed weekly): not in `home/dot_claude/rules/`, or chezmoi would see two sources for one target

Why `home/` and not the repo root: with the repo root as source state, every file not starting with `.` (`README.md`, `CLAUDE.md`, `brew/`, `scripts/`) would be deployed to `$HOME` unless listed in a `.chezmoiignore`. `CLAUDE.md` in `~` would load into every Claude Code session under the home directory.

## Machine identity — `machine_type` and `git_email`

Machine-specific values live **outside the repo**, so it stays publishable without personal data. Both are asked by `home/.chezmoi.toml.tmpl` on the **first** `init` and saved in `~/.config/chezmoi/chezmoi.toml` (untracked); later inits read them back from there without asking again:

| Value          | Template function                                                      |
|----------------|------------------------------------------------------------------------|
| `machine_type` | `promptChoiceOnce . "machine_type" "machine_type" (list "personal" "work")` |
| `git_email`    | `promptStringOnce . "git_email" "git_email"`                           |

`machine_type` drives:
1. The templates: `home/dot_zshrc.tmpl` (gcloud completions, `AWS_PROFILE`, `KUBECONFIG`, the `awsp` function, `_load_kubeconfig`)
2. The packages script: which `Brewfile.<machine_type>` to install

This machine is `"work"`.

`home/dot_gitconfig.tmpl` emits the `email` line only when it has a value, so a missing value produces a `~/.gitconfig` without `email` and git asks for an identity on the first commit — an explicit failure instead of a silently wrong email.

**Without a TTY the prompts abort** (`could not open a new TTY`). For non-interactive use:

```bash
chezmoi init --apply --source=. --promptChoice machine_type=work --promptString git_email=you@example.com
```

`--promptChoice` / `--promptString` match the **prompt text** (third argument), not the data key: in the template the two are deliberately identical, so the `machine_type=` and `git_email=` keys keep working.

When adding more personal data used only by the templates, follow this path instead of writing it into the repo.

To test the templates with a specific value, render them against an isolated config instead of the real one:
```bash
chezmoi --config /tmp/cz.toml init --source=. --promptChoice machine_type=personal --promptString git_email=x@example.invalid
chezmoi --config /tmp/cz.toml execute-template < home/dot_zshrc.tmpl
```

When touching a template with `{{ if eq .machine_type ... }}` branches, verify **both** values.
