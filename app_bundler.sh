#!/usr/bin/env bash

# app_bundler.sh
# Before running the script ensure its executable: chmod +x app_bundler.sh (This will make the script executable)
# Usage: ./app_bundler.sh <APP_NAME> <BUNDLE_ID> <VERSION> <EXECUTABLE_PATH> <ICON_PATH>
# Example: ./app_bundler.sh CoolApp com.example.example_app 1.0 ./build/app ./ASSETS/icon.icns

set -euo pipefail

if [ $# -ne 5 ]; then
  echo "Usage: $0 <APP_NAME> <BUNDLE_ID> <VERSION> <EXECUTABLE_PATH> <ICON_PATH>"
  exit 1
fi

APP_NAME="$1"
BUNDLE_ID="$2"
VERSION="$3"
EXECUTABLE_PATH="$4"
ICON_SOURCE="$5"

APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${EXECUTABLE_PATH}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

ICON_NAME=$(basename "${ICON_SOURCE}")
ICON_BASE="${ICON_NAME%.*}"

if [[ "${ICON_SOURCE}" == *.png ]]; then
  ICONSET_DIR="${RESOURCES_DIR}/${ICON_BASE}.iconset"
  mkdir -p "${ICONSET_DIR}"
  for size in 16 32 64 128 256 512; do
    sips -z $size $size "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_${size}x${size}.png"
    sips -z $(($size*2)) $(($size*2)) "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_${size}x${size}@2x.png"
  done
  iconutil -c icns "${ICONSET_DIR}" --output "${RESOURCES_DIR}/${ICON_BASE}.icns"
else
  cp "${ICON_SOURCE}" "${RESOURCES_DIR}/${ICON_NAME}"
fi

# Info.plist
cat > "${CONTENTS_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIconFile</key>
  <string>${ICON_BASE}.icns</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.10.0</string>
</dict>
</plist>
EOF

echo "Built ${APP_DIR} successfully."
