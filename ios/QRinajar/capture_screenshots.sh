#!/bin/bash
set -euo pipefail

DEVICE="iPhone 17 Pro"
BUNDLE_ID="com.qrinajar.app"
OUT_DIR="$(cd "$(dirname "$0")" && pwd)/screenshots"
mkdir -p "$OUT_DIR"

TABS=(type 0 data 1 style 2 export 3)

capture_appearance() {
  local appearance="$1"
  xcrun simctl ui "$DEVICE" appearance "$appearance"
  sleep 1

  local i=0
  while [ "$i" -lt "${#TABS[@]}" ]; do
    name="${TABS[$i]}"
    idx="${TABS[$((i+1))]}"
    i=$((i+2))

    xcrun simctl terminate "$DEVICE" "$BUNDLE_ID" >/dev/null 2>&1 || true
    sleep 1

    SIMCTL_CHILD_QRINAJAR_TAB="$idx" xcrun simctl launch "$DEVICE" "$BUNDLE_ID" >/dev/null

    # settle delay for view to render
    sleep 2

    xcrun simctl io "$DEVICE" screenshot "$OUT_DIR/${name}-${appearance}.png"
    echo "captured ${name}-${appearance}.png"
  done
}

capture_appearance light
capture_appearance dark

xcrun simctl terminate "$DEVICE" "$BUNDLE_ID" >/dev/null 2>&1 || true
echo "done"
