#!/usr/bin/env bash
# Shared paths for AtomVM test scripts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ATOMVM_VERSION="${ATOMVM_VERSION:-v0.7.0-beta.0}"
ATOMVM_CACHE="${ATOMVM_CACHE:-$ROOT/.atomvm/$ATOMVM_VERSION}"
RELEASE_BASE="https://github.com/atomvm/AtomVM/releases/download/${ATOMVM_VERSION}"

TESTS_AVM="${TESTS_AVM:-$ROOT/build/tests.avm}"
PACKBEAM_BIN="${PACKBEAM_BIN:-$ATOMVM_CACHE/bin/packbeam}"
QEMU_BIN="${QEMU_BIN:-$ATOMVM_CACHE/bin/qemu-system-xtensa}"
# Espressif QEMU fork (stock QEMU lacks the `esp32` machine).
ESPRESSIF_QEMU_VER="${ESPRESSIF_QEMU_VER:-esp-develop-9.2.2-20260417}"
ESPRESSIF_QEMU_BUILD="${ESPRESSIF_QEMU_BUILD:-esp_develop_9.2.2_20260417}"

mkdir -p "$ATOMVM_CACHE/bin" "$ATOMVM_CACHE/unix" "$ATOMVM_CACHE/wasm" "$ATOMVM_CACHE/esp32" "$ATOMVM_CACHE/pico" "$ATOMVM_CACHE/libs" "$ATOMVM_CACHE/qemu"

download() {
  local url="$1"
  local dest="$2"
  if [[ -f "$dest" ]]; then
    return 0
  fi
  echo "Downloading $url"
  curl -fsSL -o "$dest.partial" "$url"
  mv "$dest.partial" "$dest"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
}

assert_ok_marker() {
  local log_file="$1"
  if grep -q 'AVM_GLEAM_TESTS_OK' "$log_file"; then
    echo "PASS: AVM_GLEAM_TESTS_OK"
    return 0
  fi
  echo "FAIL: missing AVM_GLEAM_TESTS_OK" >&2
  if grep -q 'AVM_GLEAM_TESTS_FAIL' "$log_file"; then
    grep 'AVM_GLEAM_TESTS_FAIL\|FAIL ' "$log_file" >&2 || true
  fi
  return 1
}
