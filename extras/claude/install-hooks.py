#!/usr/bin/env python3
"""Install (or --uninstall) the Caelestia agents-tracker hooks into Claude Code settings.

Idempotent. Preserves every other setting and hook. Backs up settings.json to
settings.json.bak-caelestia before writing.

Usage: install-hooks.py [--uninstall] [--settings PATH] [--dry-run]
"""

import argparse
import json
import os
import shutil
import sys
import tempfile

EVENTS = [
    "SessionStart",
    "UserPromptSubmit",
    "PreToolUse",
    "PostToolUse",
    "SubagentStart",
    "SubagentStop",
    "Notification",
    "Stop",
    "SessionEnd",
]
MARKER = "caelestia-agents-hook.py"
HOOK_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), MARKER)


def default_settings_path():
    cfg = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")
    return os.path.join(cfg, "settings.json")


def is_ours(hook):
    return isinstance(hook, dict) and MARKER in str(hook.get("command", ""))


def strip_ours(hooks_section):
    """Remove our hook commands from every event; drop groups/events left empty."""
    for event in list(hooks_section):
        groups = hooks_section[event]
        if not isinstance(groups, list):
            continue
        new_groups = []
        for group in groups:
            if not isinstance(group, dict) or not isinstance(group.get("hooks"), list):
                new_groups.append(group)
                continue
            had_ours = any(is_ours(h) for h in group["hooks"])
            kept = [h for h in group["hooks"] if not is_ours(h)]
            if kept or not had_ours:
                group = dict(group, hooks=kept)
                new_groups.append(group)
        if new_groups:
            hooks_section[event] = new_groups
        else:
            del hooks_section[event]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--uninstall", action="store_true", help="remove the Caelestia hooks")
    ap.add_argument("--settings", default=default_settings_path(), help="settings.json path")
    ap.add_argument("--dry-run", action="store_true", help="print the result instead of writing")
    args = ap.parse_args()

    path = args.settings
    if os.path.exists(path):
        with open(path) as f:
            text = f.read()
        try:
            settings = json.loads(text) if text.strip() else {}
        except ValueError as e:
            sys.exit("error: %s is not valid JSON (%s); refusing to modify it" % (path, e))
        if not isinstance(settings, dict):
            sys.exit("error: %s top level is not an object; refusing to modify it" % path)
    else:
        settings = {}

    hooks = settings.get("hooks")
    if hooks is None:
        hooks = {}
    if not isinstance(hooks, dict):
        sys.exit("error: 'hooks' in %s is not an object; refusing to modify it" % path)

    strip_ours(hooks)
    if not args.uninstall:
        if not os.path.isfile(HOOK_PATH):
            sys.exit("error: hook script not found at %s" % HOOK_PATH)
        command = "python3 '%s'" % HOOK_PATH.replace("'", "'\\''")
        for event in EVENTS:
            groups = hooks.setdefault(event, [])
            if not isinstance(groups, list):
                sys.exit("error: hooks.%s is not a list; refusing to modify it" % event)
            groups.append({"hooks": [{"type": "command", "command": command, "timeout": 5}]})

    if hooks:
        settings["hooks"] = hooks
    else:
        settings.pop("hooks", None)

    out = json.dumps(settings, indent=2, ensure_ascii=False) + "\n"
    if args.dry_run:
        sys.stdout.write(out)
        return

    if os.path.exists(path) and out == text:
        print("No changes needed in %s" % path)
        return

    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    if os.path.exists(path):
        shutil.copy2(path, path + ".bak-caelestia")
    fd, tmp = tempfile.mkstemp(prefix=".settings.", suffix=".tmp", dir=os.path.dirname(os.path.abspath(path)))
    try:
        with os.fdopen(fd, "w") as f:
            f.write(out)
        if os.path.exists(path):
            shutil.copymode(path, tmp)
        os.replace(tmp, path)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise

    if args.uninstall:
        print("Removed Caelestia agent hooks from %s (backup: %s.bak-caelestia)" % (path, path))
    else:
        print("Installed Caelestia agent hooks for %d events into %s (backup: %s.bak-caelestia)" % (len(EVENTS), path, path))
    print("Restart running Claude Code sessions (or run /hooks) for the change to take effect.")


if __name__ == "__main__":
    main()
