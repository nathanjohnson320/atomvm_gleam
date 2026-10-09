#!/usr/bin/env bash
# Compile Gleam (incl. test harness) and pack build/tests.avm for AtomVM.
#
# Usage:
#   ./scripts/pack_avm_tests.sh           # include atomvmlib (unix / wasm)
#   ./scripts/pack_avm_tests.sh --no-libs # app beams only (ESP32 firmware supplies libs)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

WITH_LIBS=1
for arg in "$@"; do
  case "$arg" in
    --no-libs) WITH_LIBS=0 ;;
    -h|--help)
      sed -n '2,7p' "$0"
      exit 0
      ;;
    *)
      echo "error: unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

require_cmd gleam
require_cmd erlc

"$SCRIPT_DIR/fetch_atomvm.sh" packbeam
if [[ "$WITH_LIBS" -eq 1 ]]; then
  "$SCRIPT_DIR/fetch_atomvm.sh" libs
fi

echo "Compiling Gleam project + tests…"
(
  cd "$ROOT"
  gleam test
)

EBIN="$ROOT/build/dev/erlang/atomvm_gleam/ebin"
mkdir -p "$EBIN"
erlc -o "$EBIN" \
  "$SCRIPT_DIR/avm_test_env_ffi.erl" \
  "$SCRIPT_DIR/avm_http_test_handler.erl"

STDLIB_EBIN="$ROOT/build/dev/erlang/gleam_stdlib/ebin"
ERLANG_EBIN="$ROOT/build/dev/erlang/gleam_erlang/ebin"
ATOMVMLIB="$ATOMVM_CACHE/libs/atomvmlib.avm"

LIST_FILE="$(mktemp)"
{
  echo "$EBIN/avm@runner.beam"
  find "$EBIN" -name 'avm@*.beam' ! -name 'avm@runner.beam'
  find "$EBIN" -name 'atomvm_gleam*.beam' ! -name 'atomvm_gleam_test.beam'
  find "$EBIN" -name 'avm_test_env_ffi.beam'
  find "$EBIN" -name 'avm_http_test_handler.beam'
  find "$STDLIB_EBIN" -name '*.beam'
  find "$ERLANG_EBIN" -name '*.beam'
} >"$LIST_FILE"

mkdir -p "$(dirname "$TESTS_AVM")"
rm -f "$TESTS_AVM"

BEAM_COUNT="$(wc -l <"$LIST_FILE" | tr -d ' ')"
echo "Packing $BEAM_COUNT beams → $TESTS_AVM (atomvmlib=$WITH_LIBS)"

# Do not use --prune: Gleam's higher-order suite dispatch is not visible to
# packbeam's BEAM call-graph analysis and would drop harness modules.
# shellcheck disable=SC2046
if [[ "$WITH_LIBS" -eq 1 ]]; then
  if [[ ! -f "$ATOMVMLIB" ]]; then
    echo "error: missing $ATOMVMLIB (run ./scripts/fetch_atomvm.sh libs)" >&2
    exit 1
  fi
  "$PACKBEAM_BIN" create -s "avm@runner" "$TESTS_AVM" $(cat "$LIST_FILE") "$ATOMVMLIB"
else
  # ESP32/Pico/STM32 images already ship platform libs. Bundling a host-built
  # atomvmlib.avm shadows modules like gpio with the unix variants.
  "$PACKBEAM_BIN" create -s "avm@runner" "$TESTS_AVM" $(cat "$LIST_FILE")
fi
rm -f "$LIST_FILE"

"$PACKBEAM_BIN" list "$TESTS_AVM" >/dev/null
echo "Wrote $TESTS_AVM ($(wc -c <"$TESTS_AVM" | tr -d ' ') bytes)"
