# Claude Code agents tracker (hooks)

Claude Code hooks that feed the Caelestia "Claude agents" bar popout.

- `caelestia-agents-hook.py`: hook script (python3, stdlib only). It reads the hook
  payload from stdin and keeps one state file per session in
  `${XDG_RUNTIME_DIR:-/tmp}/caelestia/claude-agents/<session_id>.json`. It never writes
  to stdout and always exits 0. A typical call takes about 15 ms.
- `install-hooks.py`: registers the hook for SessionStart, UserPromptSubmit,
  PreToolUse, PostToolUse, SubagentStart, SubagentStop, Notification, Stop and
  SessionEnd in `${CLAUDE_CONFIG_DIR:-~/.claude}/settings.json`. Every other setting
  and hook stays as it was. Running it again is safe, and it writes
  `settings.json.bak-caelestia` before it changes anything.

```sh
python3 install-hooks.py              # install / repair
python3 install-hooks.py --dry-run    # print resulting settings.json
python3 install-hooks.py --uninstall  # remove only the Caelestia hooks
```

New sessions pick up the hooks. For a session that is already running, restart it or
open `/hooks`. Sessions without hooks still appear through the watcher's fallback
(`~/.claude/sessions/*.json`), but they show fewer details.

The state file format is defined by the shared contract (v1). The `pendingAgents` key
and the per-subagent `currentTool` key are extras that the hook uses for its own
bookkeeping.
