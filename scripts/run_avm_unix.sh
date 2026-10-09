#!/usr/bin/env bash
# Run the AtomVM harness on generic_unix.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

"$SCRIPT_DIR/fetch_atomvm.sh" unix
"$SCRIPT_DIR/pack_avm_tests.sh"

ATOMVM_BIN="$ATOMVM_CACHE/unix/AtomVM"
ATOMVMLIB="$ATOMVM_CACHE/libs/atomvmlib.avm"
LOG="$(mktemp)"

# AtomVM may be linked against $MBEDTLS_PREFIX (3.6+), not distro 2.28.
export_mbedtls_lib_path

echo "Running: $ATOMVM_BIN $TESTS_AVM $ATOMVMLIB"
set +e
"$ATOMVM_BIN" "$TESTS_AVM" "$ATOMVMLIB" 2>&1 | tee "$LOG"
status=${PIPESTATUS[0]}
set -e

assert_ok_marker "$LOG"
exit_code=$?
rm -f "$LOG"
if [[ $status -ne 0 && $exit_code -eq 0 ]]; then
  exit 0
fi
exit "$exit_code"
