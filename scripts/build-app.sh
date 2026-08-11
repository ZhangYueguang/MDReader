#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd -P)
repository_root=$(cd "$script_dir/.." && pwd -P)
app_path="$repository_root/dist/MDReader.app"
contents_path="$app_path/Contents"
executable_path="$repository_root/.build/release/MDReader"
resource_destination="$contents_path/Resources/MDReader_MDReaderKit.bundle"
icon_path="$repository_root/Assets/MDReader.icns"

cd "$repository_root"

npm ci
npm test
npm run build:web
swift run MDReaderTests
swift build -c release --product MDReader

if [[ ! -x "$executable_path" ]]; then
  printf 'Release executable is missing: %s\n' "$executable_path" >&2
  exit 1
fi

if [[ ! -s "$icon_path" ]]; then
  printf 'Application icon is missing: %s\n' "$icon_path" >&2
  exit 1
fi

resource_bundle=$(find "$repository_root/.build" -maxdepth 4 -type d -path '*/release/MDReader_MDReaderKit.bundle' -print -quit)
if [[ -z "$resource_bundle" || "$resource_bundle" != "$repository_root/.build/"* ]]; then
  printf 'Release resource bundle was not found inside .build\n' >&2
  exit 1
fi

if [[ -e "$app_path" ]]; then
  if [[ "$app_path" != "$repository_root/dist/MDReader.app" ]]; then
    printf 'Refusing to replace unexpected app path: %s\n' "$app_path" >&2
    exit 1
  fi
  rm -rf "$app_path"
fi

mkdir -p "$contents_path/MacOS" "$contents_path/Resources"
cp "$executable_path" "$contents_path/MacOS/MDReader"
chmod 755 "$contents_path/MacOS/MDReader"
cp "$repository_root/Config/Info.plist" "$contents_path/Info.plist"
cp "$icon_path" "$contents_path/Resources/MDReader.icns"
cp -R "$resource_bundle" "$resource_destination"
printf 'APPL????' > "$contents_path/PkgInfo"

bundle_identifier=$(plutil -extract CFBundleIdentifier raw "$contents_path/Info.plist")
signed=false
for _ in 1 2 3; do
  # File Provider may reattach Finder metadata immediately after a bundle is
  # created inside Documents. Clear it immediately before each signing try.
  xattr -cr "$app_path"
  if codesign --force --sign - --identifier "$bundle_identifier" "$app_path"; then
    signed=true
    break
  fi
done
if [[ "$signed" != true ]]; then
  printf 'Unable to sign %s after clearing extended attributes\n' "$app_path" >&2
  exit 1
fi
verified=false
for _ in 1 2 3; do
  xattr -cr "$app_path"
  if "$repository_root/scripts/verify-app.sh" "$app_path"; then
    verified=true
    break
  fi
done
if [[ "$verified" != true ]]; then
  printf 'Unable to verify %s after clearing extended attributes\n' "$app_path" >&2
  exit 1
fi

printf 'Built %s\n' "$app_path"
