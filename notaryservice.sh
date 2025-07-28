#!/usr/bin/env bash

# notaryservice.sh
# Usage: ./notaryservice.sh <APP_PATH>
# Example: ./notaryservice.sh MyApp  (interactive exchange)

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <APP_PATH>"
  exit 1
fi
APP_PATH="$1"

echo "Select notarization mode:"
echo "  1) Manual credentials"
echo "  2) Keychain profile"
read -p "Enter choice [1/2]: " MODE
if [[ "$MODE" == "1" ]]; then
  read -p "Apple ID: " APPLE_ID
  read -s -p "App-specific password: " APP_PW; echo
  read -p "Team ID: " TEAM_ID
elif [[ "$MODE" == "2" ]]; then
  read -p "Keychain profile name: " KEYCHAIN_PROFILE
  if ! xcrun notarytool store-credentials list | grep -q "^${KEYCHAIN_PROFILE}$"; then
    echo "Keychain profile '${KEYCHAIN_PROFILE}' not found. Exiting."
    exit 1
  fi
else
  echo "Invalid choice. Exiting."
  exit 1
fi

ZIP_PATH="${APP_PATH}.zip"

if [[ "$MODE" == "1" ]]; then
  echo "Submitting ${ZIP_PATH} with notarytool (manual credentials mode)"
  xcrun notarytool submit "${ZIP_PATH}" \
    --apple-id "${APPLE_ID}" --password "${APP_PW}" \
    --team-id "${TEAM_ID}" --wait
elif [[ "$MODE" == "2" ]]; then
  echo "Submitting ${ZIP_PATH} with notarytool using profile '${KEYCHAIN_PROFILE}'"
  xcrun notarytool submit "${ZIP_PATH}" \
    --keychain-profile "${KEYCHAIN_PROFILE}" --wait
fi


echo "Stapling ticket to ${APP_PATH}"
xcrun stapler staple "${APP_PATH}"

echo "Notary service workflow completed for ${APP_PATH}"