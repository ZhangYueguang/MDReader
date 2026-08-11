#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd -P)
repository_root=$(cd "$script_dir/.." && pwd -P)
app_path=${1:-"$repository_root/dist/MDReader.app"}
resource_bundle="$app_path/Contents/Resources/MDReader_MDReaderKit.bundle"

if [[ ! -d "$app_path" ]]; then
  printf 'App is missing: %s\n' "$app_path" >&2
  exit 1
fi
if [[ -e "$app_path/MDReader_MDReaderKit.bundle" ]]; then
  printf 'Resource bundle must not be stored at the application root.\n' >&2
  exit 1
fi

plutil -lint "$app_path/Contents/Info.plist"
test -x "$app_path/Contents/MacOS/MDReader"
test -s "$app_path/Contents/Resources/MDReader.icns"
test "$(plutil -extract CFBundleIconFile raw "$app_path/Contents/Info.plist")" = "MDReader.icns"
test -s "$resource_bundle/GeneratedResources/app/renderer.js"
test -s "$resource_bundle/GeneratedResources/app/reader.css"
test -s "$resource_bundle/GeneratedResources/mathjax/tex-mml-chtml.js"
test -s "$resource_bundle/GeneratedResources/mathjax/output/fonts/mathjax-newcm/chtml/dynamic/calligraphic.js"
test -s "$resource_bundle/GeneratedResources/mathjax/output/fonts/mathjax-newcm/chtml/woff2/mjx-ncm-c.woff2"
if xattr -p com.apple.FinderInfo "$app_path" >/dev/null 2>&1; then
  codesign --verify --deep --verbose=2 "$app_path"
else
  codesign --verify --deep --strict --verbose=2 "$app_path"
fi

printf 'Verified %s\n' "$app_path"
