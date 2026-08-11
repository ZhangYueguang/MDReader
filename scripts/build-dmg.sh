#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd -P)
repository_root=$(cd "$script_dir/.." && pwd -P)
skip_build=false

usage() {
  printf 'Usage: %s [--skip-build]\n' "$(basename "$0")"
}

while (($#)); do
  case "$1" in
    --skip-build)
      skip_build=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
  shift
done

version=$(plutil -extract CFBundleShortVersionString raw "$repository_root/Config/Info.plist")
app_path="$repository_root/dist/MDReader.app"
release_dir="$repository_root/release"
dmg_name="MDReader-$version.dmg"
dmg_path="$release_dir/$dmg_name"
volume_name="MDReader $version"

if [[ "$skip_build" == false ]]; then
  "$repository_root/scripts/build-app.sh"
fi

if [[ ! -d "$app_path" ]]; then
  printf 'Application is missing: %s\n' "$app_path" >&2
  printf 'Run without --skip-build to build it first.\n' >&2
  exit 1
fi
"$repository_root/scripts/verify-app.sh" "$app_path" >/dev/null

temporary_root=$(mktemp -d "${TMPDIR:-/tmp}/mdreader-release.XXXXXX")
staging_path="$temporary_root/staging"
read_write_dmg="$temporary_root/MDReader-rw.dmg"
attach_plist="$temporary_root/attach.plist"
mount_point=""

cleanup() {
  if [[ -n "$mount_point" && -d "$mount_point" ]]; then
    hdiutil detach "$mount_point" -quiet || hdiutil detach "$mount_point" -force -quiet || true
  fi
  if [[ -d "$temporary_root" && "$temporary_root" == "${TMPDIR:-/tmp}/mdreader-release."* ]]; then
    rm -rf "$temporary_root"
  fi
}
trap cleanup EXIT

mkdir -p "$staging_path/.background" "$release_dir"
ditto --noextattr --noqtn "$app_path" "$staging_path/MDReader.app"
ln -s /Applications "$staging_path/Applications"
swift "$repository_root/scripts/generate-dmg-background.swift" \
  "$staging_path/.background/install-background.png"

hdiutil create \
  -volname "$volume_name" \
  -srcfolder "$staging_path" \
  -fs HFS+ \
  -format UDRW \
  -ov \
  "$read_write_dmg" \
  -quiet

hdiutil attach "$read_write_dmg" \
  -readwrite \
  -nobrowse \
  -noverify \
  -plist > "$attach_plist"

for index in 0 1 2 3 4 5; do
  candidate=$(/usr/libexec/PlistBuddy \
    -c "Print :system-entities:$index:mount-point" "$attach_plist" 2>/dev/null || true)
  if [[ -n "$candidate" && -d "$candidate" ]]; then
    mount_point="$candidate"
    break
  fi
done

if [[ -z "$mount_point" ]]; then
  printf 'Unable to locate the mounted disk image.\n' >&2
  exit 1
fi

layout_log="$temporary_root/finder-layout.log"
osascript - "$volume_name" >"$layout_log" 2>&1 <<'APPLESCRIPT' &
on run arguments
  set volumeName to item 1 of arguments
  tell application "Finder"
    tell disk volumeName
      open
      set current view of container window to icon view
      set toolbar visible of container window to false
      set statusbar visible of container window to false
      set bounds of container window to {140, 140, 800, 540}
      set theOptions to icon view options of container window
      set arrangement of theOptions to not arranged
      set icon size of theOptions to 104
      set text size of theOptions to 13
      set background picture of theOptions to file ".background:install-background.png"
      set position of item "MDReader.app" of container window to {170, 220}
      set position of item "Applications" of container window to {490, 220}
      close
    end tell
  end tell
end run
APPLESCRIPT

layout_pid=$!
layout_finished=false
for _ in {1..40}; do
  if ! kill -0 "$layout_pid" 2>/dev/null; then
    layout_finished=true
    break
  fi
  sleep 0.2
done

if [[ "$layout_finished" == false ]]; then
  kill "$layout_pid" 2>/dev/null || true
  wait "$layout_pid" 2>/dev/null || true
  printf 'Finder layout timed out; continuing with a standard icon view.\n' >&2
elif wait "$layout_pid"; then
  printf 'Applied the Finder installation layout.\n'
else
  sed -n '1,20p' "$layout_log" >&2
  printf 'Finder layout was unavailable; continuing with a standard icon view.\n' >&2
fi

sync
hdiutil detach "$mount_point" -quiet
mount_point=""

rm -f "$dmg_path"
hdiutil convert "$read_write_dmg" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$dmg_path" \
  -quiet

(
  cd "$release_dir"
  shasum -a 256 "$dmg_name" > SHA256SUMS
)

"$repository_root/scripts/verify-dmg.sh" "$dmg_path"
printf 'Built %s\n' "$dmg_path"
printf 'Wrote %s\n' "$release_dir/SHA256SUMS"
