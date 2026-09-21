#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
if ! XCODE_VERSION="$(xcodebuild -version 2>/dev/null)"; then
  echo 'Установите полный Xcode и выберите его в Xcode → Settings → Locations → Command Line Tools.'
  exit 1
fi
XCODE_MAJOR="$(awk '/^Xcode / {split($2, version, "."); print version[1]}' <<< "$XCODE_VERSION")"
if [[ ! "$XCODE_MAJOR" =~ ^[0-9]+$ ]] || [ "$XCODE_MAJOR" -lt 26 ]; then
  echo 'Для сборки нужен Xcode 26 или новее (SDK с поддержкой Liquid Glass).'
  exit 1
fi
DEVICE_ID="$(xcrun simctl list devices available -j | python3 scripts/select-simulator.py)" || DEVICE_ID=""
if [ -z "$DEVICE_ID" ]; then
  echo 'Нужен доступный симулятор iPhone с iOS 18 или новее.'
  echo 'Загрузите iOS Simulator в Xcode → Settings → Components и создайте iPhone в Window → Devices and Simulators.'
  echo 'Если задан GETBUKET_DEVICE_ID, проверьте его значение.'
  exit 1
fi
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_ID" -b
xcodebuild -quiet -project GetBuket.xcodeproj -scheme GetBuket -configuration Debug -sdk iphonesimulator -destination "platform=iOS Simulator,id=$DEVICE_ID" -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
xcrun simctl install "$DEVICE_ID" build/Build/Products/Debug-iphonesimulator/GetBuket.app
xcrun simctl status_bar "$DEVICE_ID" override --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
xcrun simctl terminate "$DEVICE_ID" studio.getbuket.vision 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" studio.getbuket.vision "$@"
open -a Simulator
