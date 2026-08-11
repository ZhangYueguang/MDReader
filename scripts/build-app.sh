#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd -P)
repository_root=$(cd "$script_dir/.." && pwd -P)
final_app_path="$repository_root/dist/MDReader.app"
temporary_root=$(mktemp -d "${TMPDIR:-/tmp}/mdreader-app.XXXXXX")
app_path="$temporary_root/MDReader.app"
contents_path="$app_path/Contents"
executable_path="$repository_root/.build/release/MDReader"
resource_destination="$contents_path/Resources/MDReader_MDReaderKit.bundle"
icon_path="$repository_root/Assets/MDReader.icns"

cleanup() {
  if [[ -d "$temporary_root" && "$temporary_root" == "${TMPDIR:-/tmp}/mdreader-app."* ]]; then
    rm -rf "$temporary_root"
  fi
}
trap cleanup EXIT

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
  # Clear metadata inherited from source files immediately before signing.
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

if [[ "$final_app_path" != "$repository_root/dist/MDReader.app" ]]; then
  printf 'Refusing to replace unexpected app path: %s\n' "$final_app_path" >&2
  exit 1
fi
if [[ -e "$final_app_path" ]]; then
  rm -rf "$final_app_path"
fi
mkdir -p "$(dirname "$final_app_path")"
ditto --noextattr --noqtn "$app_path" "$final_app_path"
"$repository_root/scripts/verify-app.sh" "$final_app_path"

printf 'Built %s\n' "$final_app_path"
