# Desktop Integration Worker Task

## Objective

Implement the shared desktop-integration layer for:

- Notification grouping.
- Keyboard navigation for notifications.
- Calendar agenda.
- Separate idle policies for AC power and battery power.
- Config schema.
- Config defaults.
- Config migration.
- Settings navigation.
- Shared integration points required by the parallel workers.

## Required approach

- This worker owns the shared config, settings, and migration files for this
  phase.
- Review `INTEGRATION_NOTES.md` and coordinate shared contracts without
  reimplementing another worker's feature.
- Keep integrations asynchronous so the QML UI thread is never blocked.
- Make optional dependencies degrade gracefully when unavailable.
- Preserve Caelestia's codebase, branding, visual style, and existing
  fluid/morphing animation language.
- Build and test all changes before committing.
- Keep this worktree's `INTEGRATION_NOTES.md` current with shared decisions and
  integration requirements.

## Ownership boundaries

- Do not independently reimplement Launcher, System Tools, or Control Center
  functionality assigned to the other three workers.
- A plugin system is explicitly outside the current phase; do not implement it.
- Do not work outside the scope above, do not modify another worktree, and do
  not merge another worker's branch.
