#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd -P)
repository_root=$(cd "$script_dir/.." && pwd -P)
app_path="$repository_root/dist/MDReader.app"
fixture_path=${1:-"$repository_root/Tests/Fixtures/Showcase.md"}

if [[ ! -d "$app_path" ]]; then
  printf 'App is missing. Run scripts/build-app.sh first.\n' >&2
  exit 1
fi
"$repository_root/scripts/verify-app.sh" "$app_path"
if [[ ! -f "$fixture_path" ]]; then
  printf 'Fixture is missing: %s\n' "$fixture_path" >&2
  exit 1
fi

existing_pids=$(pgrep -x MDReader 2>/dev/null || true)
open -n -a "$app_path" "$fixture_path"

launched_pid=""
for _attempt in $(seq 1 30); do
  current_pids=$(pgrep -x MDReader 2>/dev/null || true)
  for pid in $current_pids; do
    if ! grep -qx "$pid" <<< "$existing_pids"; then
      launched_pid=$pid
      break 2
    fi
  done
  sleep 0.5
done

if [[ -z "$launched_pid" ]]; then
  printf 'MDReader did not launch within 15 seconds.\n' >&2
  exit 1
fi

sleep 2
if ! kill -0 "$launched_pid" 2>/dev/null; then
  printf 'MDReader exited before the smoke test completed.\n' >&2
  exit 1
fi

printf 'Smoke test passed with process %s\n' "$launched_pid"
kill "$launched_pid"
