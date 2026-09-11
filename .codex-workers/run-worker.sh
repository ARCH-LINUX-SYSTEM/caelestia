#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: run-worker.sh <worker>

Workers:
  launcher
  system-tools
  control-center
  desktop-integration
EOF
}

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 64
fi

worker=$1

case "$worker" in
    launcher)
        expected_branch="feat/dms-launcher"
        ;;
    system-tools)
        expected_branch="feat/dms-system-tools"
        ;;
    control-center)
        expected_branch="feat/dms-control-center"
        ;;
    desktop-integration)
        expected_branch="feat/dms-desktop-integration"
        ;;
    *)
        printf 'Error: unknown worker: %s\n\n' "$worker" >&2
        usage >&2
        exit 64
        ;;
esac

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel)
parent_dir=$(dirname -- "$repo_root")
worktree="$parent_dir/caelestia-workers/$worker"

if ! command -v codex >/dev/null 2>&1; then
    printf 'Error: the codex command is not available in PATH.\n' >&2
    exit 127
fi

if [[ ! -d "$worktree" ]]; then
    printf 'Error: worker worktree does not exist: %s\n' "$worktree" >&2
    printf 'Run the setup or inspect .codex-workers/check-workers.sh first.\n' >&2
    exit 1
fi

if ! git -C "$worktree" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'Error: path is not a Git worktree: %s\n' "$worktree" >&2
    exit 1
fi

current_branch=$(git -C "$worktree" branch --show-current)
if [[ "$current_branch" != "$expected_branch" ]]; then
    printf 'Error: refusing to start worker in the wrong branch.\n' >&2
    printf 'Worktree: %s\n' "$worktree" >&2
    printf 'Expected: %s\n' "$expected_branch" >&2
    printf 'Actual:   %s\n' "${current_branch:-DETACHED_HEAD}" >&2
    exit 1
fi

printf '\n'
printf 'WARNING: starting Codex worker "%s" in YOLO/full-access mode.\n' "$worker" >&2
printf 'Worktree: %s\n' "$worktree" >&2
printf 'Branch:   %s\n' "$current_branch" >&2
printf 'The script will not submit a prompt automatically.\n\n' >&2

cd -- "$worktree"
exec codex --sandbox danger-full-access --ask-for-approval never
