#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GESTURE="$ROOT/assets/gesture"
WASM="$GESTURE/wasm"
mkdir -p "$WASM"

MODEL_URL="https://ghfast.top/https://raw.githubusercontent.com/faunris/ai-hand-tracking/main/data/hand_landmarker.task"
WASM_URL="https://cdn.npmmirror.com/packages/@mediapipe/tasks-vision/0.10.3/files/wasm/vision_wasm_internal.wasm"
MODEL_SHA="fbc2a30080c3c557093b5ddfc334698132eb341044ccee322ccf8bcf3607cde1"
WASM_SHA="3431f70071f3980bf13e638551e9bb333335223e35542ee768db06501f7a26f2"

fetch() {
  local url="$1" path="$2" sha="$3"
  if [ ! -f "$path" ]; then
    echo "Downloading $url"
    curl -L --fail --ssl-no-revoke --max-time 300 "$url" -o "$path"
  fi
  echo "$sha  $path" | sha256sum -c -
}

fetch "$MODEL_URL" "$GESTURE/hand_landmarker.task" "$MODEL_SHA"
fetch "$WASM_URL" "$WASM/vision_wasm_internal.wasm" "$WASM_SHA"
echo "Gesture model files are ready."
