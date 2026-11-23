$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$gestureDir = Join-Path $root 'assets\gesture'
$wasmDir = Join-Path $gestureDir 'wasm'
New-Item -ItemType Directory -Force -Path $wasmDir | Out-Null

$modelPath = Join-Path $gestureDir 'hand_landmarker.task'
$wasmPath = Join-Path $wasmDir 'vision_wasm_internal.wasm'
$modelUrl = 'https://ghfast.top/https://raw.githubusercontent.com/faunris/ai-hand-tracking/main/data/hand_landmarker.task'
$wasmUrl = 'https://cdn.npmmirror.com/packages/@mediapipe/tasks-vision/0.10.3/files/wasm/vision_wasm_internal.wasm'
$modelSha = 'fbc2a30080c3c557093b5ddfc334698132eb341044ccee322ccf8bcf3607cde1'
$wasmSha = '3431f70071f3980bf13e638551e9bb333335223e35542ee768db06501f7a26f2'

function Get-File($url, $path) {
  if (Test-Path -LiteralPath $path) { return }
  Write-Host "Downloading $url"
  curl.exe -L --fail --ssl-no-revoke --max-time 300 $url -o $path
  if ($LASTEXITCODE -ne 0) { throw "Download failed: $url" }
}

function Assert-Hash($path, $expected) {
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower()
  if ($actual -ne $expected) {
    Remove-Item -LiteralPath $path -Force
    throw "SHA-256 mismatch for $path; download again."
  }
  Write-Host "OK $path"
}

Get-File $modelUrl $modelPath
Assert-Hash $modelPath $modelSha
Get-File $wasmUrl $wasmPath
Assert-Hash $wasmPath $wasmSha
Write-Host 'Gesture model files are ready.'
