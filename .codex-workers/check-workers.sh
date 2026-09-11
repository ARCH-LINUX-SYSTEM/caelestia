#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel)
parent_dir=$(dirname -- "$repo_root")
workers_root="$parent_dir/caelestia-workers"

workers=(
    "launcher"
    "system-tools"
    "control-center"
    "desktop-integration"
)

branches=(
    "feat/dms-launcher"
    "feat/dms-system-tools"
    "feat/dms-control-center"
    "feat/dms-desktop-integration"
)

file_state() {
    local path=$1

    if [[ -f "$path" ]]; then
        printf 'present'
    else
        printf 'missing'
    fi
}

for index in "${!workers[@]}"; do
    worker=${workers[$index]}
    expected_branch=${branches[$index]}
    worktree="$workers_root/$worker"

    printf 'Worker: %s\n' "$worker"
    printf 'Path: %s\n' "$worktree"
    printf 'Exists: %s\n' "$([[ -e "$worktree" ]] && printf 'yes' || printf 'no')"
    printf 'Expected branch: %s\n' "$expected_branch"

    if [[ ! -d "$worktree" ]]; then
        printf 'Branch: unavailable\n'
        printf 'Commit: unavailable\n'
        printf 'Status: unavailable\n'
        printf 'AGENTS.md: missing\n'
        printf 'CODEX_TASK.md: missing\n'
        printf 'INTEGRATION_NOTES.md: missing\n\n'
        continue
    fi

    if ! git -C "$worktree" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf 'Branch: not a Git worktree\n'
        printf 'Commit: unavailable\n'
        printf 'Status: unavailable\n'
        printf 'AGENTS.md: %s\n' "$(file_state "$worktree/AGENTS.md")"
        printf 'CODEX_TASK.md: %s\n' "$(file_state "$worktree/CODEX_TASK.md")"
        printf 'INTEGRATION_NOTES.md: %s\n\n' "$(file_state "$worktree/INTEGRATION_NOTES.md")"
        continue
    fi

    branch=$(git -C "$worktree" branch --show-current)
    commit=$(git -C "$worktree" rev-parse --short=12 HEAD)
    status=$(git -C "$worktree" status --short)

    printf 'Branch: %s\n' "${branch:-DETACHED_HEAD}"
    printf 'Commit: %s\n' "$commit"
    printf 'Status:\n'
    if [[ -n "$status" ]]; then
        printf '%s\n' "$status"
    else
        printf '  clean\n'
    fi
    printf 'AGENTS.md: %s\n' "$(file_state "$worktree/AGENTS.md")"
    printf 'CODEX_TASK.md: %s\n' "$(file_state "$worktree/CODEX_TASK.md")"
    printf 'INTEGRATION_NOTES.md: %s\n\n' "$(file_state "$worktree/INTEGRATION_NOTES.md")"
done
