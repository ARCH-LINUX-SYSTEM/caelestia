# Parallel Worker Scope

This worktree is assigned exclusively to the Desktop Integration worker. Read
and follow `CODEX_TASK.md` before making any implementation change.

- Work only within this worker's scope as defined in `CODEX_TASK.md`.
- Do not access or modify any other worker worktree.
- Do not modify the coordinator repository.
- Do not check out another branch.
- Do not run `git pull`, `git merge`, `git rebase`, `git reset --hard`, or
  `git clean`.
- Do not force-push.
- Do not copy the DankMaterialShell interface or architecture wholesale.
- Keep Caelestia as the primary codebase, branding, and visual style.
- Preserve Caelestia's existing fluid and morphing animations.
- Do not reimplement a feature that Caelestia already provides fully.
- Do not create duplicate services.
- Do not block the QML UI thread.
- Any new dependency must degrade gracefully when unavailable.
- Do not hardcode the user, home directory, monitor, terminal, or Linux
  distribution.
- Record every required config change or shared integration point in
  `INTEGRATION_NOTES.md`.
- Build and test the implementation before committing.
- Commit and push only to the correct current branch for this worktree.
- Do not merge another branch.
