#!/usr/bin/env bash
# Run the AtomVM harness under the Node / emscripten build.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

require_cmd node
"$SCRIPT_DIR/fetch_atomvm.sh" wasm
"$SCRIPT_DIR/fetch_atomvm.sh" libs
"$SCRIPT_DIR/pack_avm_tests.sh"

MJS="$ATOMVM_CACHE/wasm/AtomVM.mjs"
ATOMVMLIB="$ATOMVM_CACHE/libs/atomvmlib.avm"
LOG="$(mktemp)"

echo "Running: node $MJS $TESTS_AVM $ATOMVMLIB"
set +e
(
  cd "$ROOT"
  node --experimental-wasm-modules "$MJS" "$TESTS_AVM" "$ATOMVMLIB"
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
