#!/usr/bin/env python3
"""Claude Code hook -> Caelestia agents tracker state file.

Reads the hook JSON payload from stdin and updates
${XDG_RUNTIME_DIR:-/tmp}/caelestia/claude-agents/<session_id>.json (contract v1).

Must be fast, must never write to stdout (some hook stdout is injected into
Claude's context) and must always exit 0.
"""

import os
import sys


def _main():
    import fcntl
    import json
    import re
    import time

    raw = sys.stdin.read()
    if not raw.strip():
        return
    payload = json.loads(raw)
    if not isinstance(payload, dict):
        return

    event = payload.get("hook_event_name") or (sys.argv[1] if len(sys.argv) > 1 else "")
    sid = str(payload.get("session_id") or "")
    if not event or not re.fullmatch(r"[A-Za-z0-9_.-]{1,128}", sid) or sid.startswith("."):
        return

    now = int(time.time() * 1000)
    base = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    state_dir = os.path.join(base, "caelestia", "claude-agents")
    os.makedirs(state_dir, mode=0o700, exist_ok=True)
    path = os.path.join(state_dir, sid + ".json")
    lock_path = os.path.join(state_dir, sid + ".lock")

    agent_id = payload.get("agent_id")  # present when the event comes from inside a subagent
    agent_id = str(agent_id) if agent_id else None

    with open(lock_path, "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)

        if event == "SessionEnd":
            for p in (path, lock_path):
                try:
                    os.unlink(p)
                except FileNotFoundError:
                    pass
            return

        state = None
        try:
            with open(path) as f:
                state = json.load(f)
            if not isinstance(state, dict):
                state = None
        except (OSError, ValueError):
            state = None

        if state is None:
            state = {
                "version": 1,
                "sessionId": sid,
                "pid": None,
                "cwd": None,
                "name": None,
                "status": "idle",
                "currentTool": None,
                "lastMessage": None,
                "startedAt": now,
                "updatedAt": now,
                "subagents": [],
            }
        if not isinstance(state.get("subagents"), list):
            state["subagents"] = []
        # Internal bookkeeping (ignored by readers): Agent/Task tool calls not yet matched.
        pending = state.get("pendingAgents")
        if not isinstance(pending, dict):
            pending = {}

        # Identity / environment, refreshed on every event.
        if not state.get("pid") or not _alive(state["pid"]):
            state["pid"] = _claude_pid()
        if payload.get("cwd") and not agent_id:
            state["cwd"] = payload["cwd"]
        elif not state.get("cwd"):
            state["cwd"] = payload.get("cwd")
        name = _session_name(state.get("pid"))
        if name:
            state["name"] = name

        subs = state["subagents"]

        def find_sub(sub_id):
            for s in subs:
                if s.get("id") == sub_id:
                    return s
            return None

        def new_sub(sub_id, sub_type, desc):
            s = {
                "id": sub_id,
                "type": sub_type or "unknown",
                "description": desc,
                "status": "running",
                "startedAt": now,
                "endedAt": None,
            }
            subs.append(s)
            return s

        def finish(s):
            if s.get("status") != "done":
                s["status"] = "done"
                s["endedAt"] = now

        tool_name = payload.get("tool_name")
        tool_input = payload.get("tool_input") if isinstance(payload.get("tool_input"), dict) else {}
        tool_use_id = payload.get("tool_use_id")
        is_agent_tool = tool_name in ("Agent", "Task")

        # Recent tool calls ("steps") per agent, used by the flow overlay.
        def steps_of(owner):
            st = owner.get("steps")
            if not isinstance(st, list):
                st = owner["steps"] = []
            return st

        def owner_for_event():
            if agent_id:
                return find_sub(agent_id)
            return state

        def push_step(owner, step):
            st = steps_of(owner)
            st.append(step)
            if len(st) > STEP_CAP:
                del st[: len(st) - STEP_CAP]

        def end_step(owner, step_id, status="done"):
            for step in reversed(steps_of(owner)):
                if step.get("id") == step_id and step.get("status") == "running":
                    step["status"] = status
                    step["endedAt"] = now
                    return

        def close_running_steps(owner):
            for step in steps_of(owner):
                if step.get("status") == "running":
                    step["status"] = "done"
                    step["endedAt"] = now

        if event == "SessionStart":
            if payload.get("source") != "compact":
                state["status"] = "idle"
                state["currentTool"] = None

        elif event == "UserPromptSubmit":
            state["status"] = "busy"
            state["lastMessage"] = None
            prompt = payload.get("prompt")
            push_step(state, {"id": "prompt:%d" % now, "tool": "Prompt", "summary": _clip(prompt) if isinstance(prompt, str) else None,
                              "status": "done", "at": now, "endedAt": now})

        elif event == "PreToolUse":
            owner = owner_for_event()
            if owner is not None and tool_name:
                push_step(owner, {"id": str(tool_use_id or "t:%d" % now), "tool": tool_name, "summary": _summary(tool_name, tool_input),
                                  "status": "running", "at": now, "endedAt": None})
            if agent_id:
                s = find_sub(agent_id)
                if s is not None:
                    s["currentTool"] = tool_name
            else:
                state["status"] = "busy"
                state["currentTool"] = tool_name
            if is_agent_tool and tool_use_id:
                # Provisional entry keyed by tool_use_id; renamed to the real agent_id on
                # SubagentStart / PostToolUse (works even if SubagentStart is unavailable).
                sub_type = tool_input.get("subagent_type") or "general-purpose"
                desc = tool_input.get("description")
                prov = "tool:" + str(tool_use_id)
                if find_sub(prov) is None:
                    new_sub(prov, sub_type, desc)
                pending[str(tool_use_id)] = {"type": sub_type, "description": desc, "ts": now, "agentId": None}

        elif event in ("PostToolUse", "PostToolUseFailure"):
            owner = owner_for_event()
            if owner is not None and tool_use_id:
                end_step(owner, str(tool_use_id), "error" if event == "PostToolUseFailure" else "done")
            if event == "PostToolUseFailure":
                event = "PostToolUse"
        if event == "PostToolUse":
            if agent_id:
                s = find_sub(agent_id)
                if s is not None:
                    s["currentTool"] = None
            else:
                state["currentTool"] = None
            if is_agent_tool and tool_use_id:
                p = pending.pop(str(tool_use_id), None) or {}
                resp = payload.get("tool_response")
                resp = resp if isinstance(resp, dict) else {}
                rid = resp.get("agentId") or resp.get("agent_id") or p.get("agentId")
                is_async = bool(resp.get("isAsync")) or resp.get("status") in ("async_launched", "running")
                desc = p.get("description") or resp.get("description") or tool_input.get("description")
                sub_type = p.get("type") or tool_input.get("subagent_type")
                prov = find_sub("tool:" + str(tool_use_id))
                s = find_sub(str(rid)) if rid else None
                if s is not None and prov is not None and prov is not s:
                    subs.remove(prov)
                elif s is None and prov is not None:
                    s = prov
                    if rid:
                        s["id"] = str(rid)
                if s is None and rid and is_async:
                    s = new_sub(str(rid), sub_type, desc)
                if s is not None:
                    if desc:
                        s["description"] = desc
                    if sub_type and s.get("type") in (None, "unknown"):
                        s["type"] = sub_type
                    if not is_async:
                        finish(s)

        elif event == "SubagentStart":
            sub_id = agent_id or ("tool:" + str(tool_use_id) if tool_use_id else "anon:%d" % now)
            sub_type = payload.get("agent_type")
            s = find_sub(sub_id)
            if s is None:
                # Enrich from the oldest unmatched pending Agent/Task call of the same type.
                match_key = None
                for k, p in sorted(pending.items(), key=lambda kv: kv[1].get("ts", 0)):
                    if p.get("agentId"):
                        continue
                    if sub_type and p.get("type") and p["type"] != sub_type:
                        continue
                    match_key = k
                    break
                prov = None
                desc = None
                if match_key is not None:
                    pending[match_key]["agentId"] = sub_id
                    desc = pending[match_key].get("description")
                    sub_type = sub_type or pending[match_key].get("type")
                    prov = find_sub("tool:" + match_key)
                if prov is not None:
                    prov["id"] = sub_id
                    prov["status"] = "running"
                    if sub_type:
                        prov["type"] = sub_type
                else:
                    new_sub(sub_id, sub_type, desc)
            else:
                s["status"] = "running"
                s["endedAt"] = None

        elif event == "SubagentStop":
            s = find_sub(agent_id) if agent_id else None
            if s is None and not agent_id:
                running = [x for x in subs if x.get("status") == "running"]
                s = running[0] if len(running) == 1 else None
            if s is not None:
                finish(s)
                s.pop("currentTool", None)
                close_running_steps(s)

        elif event == "Notification":
            state["status"] = "waiting"
            msg = payload.get("message") or payload.get("title")
            state["lastMessage"] = str(msg) if msg else None

        elif event == "Stop":
            state["status"] = "idle"
            state["currentTool"] = None
            close_running_steps(state)
            # Main turn is over: synchronous subagents are finished; background ones
            # are listed in background_tasks (when the CLI provides it).
            bg = payload.get("background_tasks")
            if isinstance(bg, list):
                alive_ids = {str(t.get("id")) for t in bg if isinstance(t, dict)}
                for s in subs:
                    if s.get("status") == "running" and s.get("id") not in alive_ids:
                        finish(s)
                        s.pop("currentTool", None)
                pending.clear()

        # Housekeeping: cap history, drop stale pending entries (> 10 min).
        done = [s for s in subs if s.get("status") == "done"]
        if len(done) > 30:
            drop = {id(s) for s in sorted(done, key=lambda s: s.get("endedAt") or 0)[: len(done) - 30]}
            subs[:] = [s for s in subs if id(s) not in drop]
        for k in [k for k, p in pending.items() if now - p.get("ts", now) > 600000]:
            pending.pop(k, None)
        state["pendingAgents"] = pending
        state["version"] = 1
        state["sessionId"] = sid
        state["updatedAt"] = now

        tmp = "%s.tmp.%d" % (path, os.getpid())
        with open(tmp, "w") as f:
            json.dump(state, f, separators=(",", ":"))
        os.replace(tmp, path)


STEP_CAP = 15


def _clip(text, limit=90):
    text = " ".join(str(text).split())
    return text if len(text) <= limit else text[: limit - 1] + "…"


def _summary(tool, inp):
    """Short human-readable description of a tool call."""
    try:
        if tool == "Bash":
            return _clip(inp.get("description") or inp.get("command") or "")
        if tool in ("Read", "Edit", "Write", "MultiEdit", "NotebookEdit"):
            path = inp.get("file_path") or inp.get("notebook_path") or ""
            return _clip(os.path.basename(path) or path)
        if tool in ("Grep", "Glob"):
            return _clip(inp.get("pattern") or "")
        if tool in ("Agent", "Task"):
            return _clip(inp.get("description") or inp.get("subagent_type") or "")
        if tool == "WebFetch":
            return _clip(inp.get("url") or "")
        if tool == "WebSearch":
            return _clip(inp.get("query") or "")
        for v in inp.values():
            if isinstance(v, str) and v.strip():
                return _clip(v)
    except Exception:
        pass
    return None


def _alive(pid):
    try:
        os.kill(int(pid), 0)
        return True
    except PermissionError:
        return True
    except (OSError, ValueError, TypeError):
        return False


def _claude_pid():
    """Walk up from our parent until a process named claude/node is found."""
    ppid = os.getppid()
    pid = ppid
    for _ in range(8):
        if pid <= 1:
            break
        try:
            with open("/proc/%d/comm" % pid) as f:
                comm = f.read().strip()
            if comm in ("claude", "node") or comm.startswith("claude"):
                return pid
            with open("/proc/%d/stat" % pid) as f:
                stat = f.read()
            pid = int(stat[stat.rindex(")") + 2:].split()[1])
        except (OSError, ValueError, IndexError):
            break
    return ppid


def _session_name(pid):
    if not pid:
        return None
    try:
        import json

        cfg = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")
        with open(os.path.join(cfg, "sessions", "%d.json" % int(pid))) as f:
            name = json.load(f).get("name")
        return str(name) if name else None
    except Exception:
        return None


if __name__ == "__main__":
    try:
        sys.stdout = open(os.devnull, "w")
        _main()
    except BaseException:
        pass
    os._exit(0)
