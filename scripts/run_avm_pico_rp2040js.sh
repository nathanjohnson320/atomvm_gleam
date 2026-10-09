#!/usr/bin/env bash
# Run the AtomVM harness under rp2040js (Pico / RP2040 emulator).
#
# Uses the release Pico-W combined UF2 + tests.avm at MAIN_AVM (0x10180000).
# Requires Node.js 20+ (see .tool-versions).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

PICO_TIMEOUT_MS="${PICO_TIMEOUT_MS:-180000}"
PICO_DIR="$SCRIPT_DIR/pico_rp2040js"
UF2="$ATOMVM_CACHE/pico/AtomVM-pico-emu-combined.uf2"
BOOTROM="$ATOMVM_CACHE/pico/bootrom.bin"

require_cmd node
require_cmd npm

"$SCRIPT_DIR/fetch_atomvm.sh" packbeam
"$SCRIPT_DIR/fetch_atomvm.sh" pico
"$SCRIPT_DIR/pack_avm_tests.sh" --no-libs

if [[ ! -f "$UF2" ]]; then
  echo "error: missing $UF2 (pico emu build failed)" >&2
  exit 1
fi
if [[ ! -f "$BOOTROM" ]]; then
  echo "error: missing $BOOTROM" >&2
  exit 1
fi

(
  cd "$PICO_DIR"
  if [[ ! -d node_modules/rp2040js ]]; then
    echo "Installing rp2040js deps under scripts/pico_rp2040js…"
    npm install --no-fund --no-audit
  fi
)

LOG="$(mktemp)"
echo "Booting rp2040js ($UF2 + $TESTS_AVM, timeout ${PICO_TIMEOUT_MS}ms)…"
set +e
(
  cd "$ROOT"
  node "$PICO_DIR/run_harness.mjs" \
    --uf2 "$UF2" \
    --avm "$TESTS_AVM" \
    --bootrom "$BOOTROM" \
    --timeout-ms "$PICO_TIMEOUT_MS"
) 2>&1 | tee "$LOG"
status=${PIPESTATUS[0]}
set -e

assert_ok_marker "$LOG"
exit_code=$?
rm -f "$LOG"
if [[ $status -ne 0 && $exit_code -eq 0 ]]; then
  exit 0
fi
exit "$exit_code"
