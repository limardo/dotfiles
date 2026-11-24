# CLAUDE.md

macOS dotfiles managed with chezmoi, for two machine profiles: `personal` and `work`.

The content is split across `.claude/`:

## Verification

- `make validate` — shellcheck + Brewfile consistency, a few seconds, on the host

Every command invoked by the chezmoi scripts or by the templates must be declared in a Brewfile:
this machine is no proof that it exists.

## Repo documentation

@.claude/docs/architecture.md
@.claude/docs/chezmoi.md
@.claude/docs/install.md
@.claude/docs/validation.md
@.claude/docs/shell.md
