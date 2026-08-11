#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd -P)
repository_root=$(cd "$script_dir/.." && pwd -P)
expected_version=$(plutil -extract CFBundleShortVersionString raw "$repository_root/Config/Info.plist")
dmg_path=${1:-"$repository_root/release/MDReader-$expected_version.dmg"}

if [[ ! -s "$dmg_path" ]]; then
  printf 'Disk image is missing: %s\n' "$dmg_path" >&2
  exit 1
fi

mount_point=$(mktemp -d "${TMPDIR:-/tmp}/mdreader-dmg.XXXXXX")
attached=false

cleanup() {
  if [[ "$attached" == true ]]; then
    hdiutil detach "$mount_point" -quiet || hdiutil detach "$mount_point" -force -quiet || true
  fi
  rmdir "$mount_point" 2>/dev/null || true
}
trap cleanup EXIT

hdiutil verify "$dmg_path" >/dev/null
hdiutil attach "$dmg_path" -readonly -nobrowse -mountpoint "$mount_point" -quiet
attached=true

app_path="$mount_point/MDReader.app"
applications_link="$mount_point/Applications"

if [[ ! -d "$app_path" ]]; then
  printf 'MDReader.app is missing from the disk image.\n' >&2
  exit 1
fi
if [[ ! -L "$applications_link" ]]; then
  printf 'The Applications link is missing from the disk image.\n' >&2
  exit 1
fi
if [[ "$(readlink "$applications_link")" != "/Applications" ]]; then
  printf 'The Applications link must point to /Applications.\n' >&2
  exit 1
fi

actual_version=$(plutil -extract CFBundleShortVersionString raw "$app_path/Contents/Info.plist")
if [[ "$actual_version" != "$expected_version" ]]; then
  printf 'Version mismatch: expected %s, found %s.\n' "$expected_version" "$actual_version" >&2
  exit 1
fi

"$repository_root/scripts/verify-app.sh" "$app_path" >/dev/null

printf 'Verified %s (MDReader %s)\n' "$dmg_path" "$actual_version"
