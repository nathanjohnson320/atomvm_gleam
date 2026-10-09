#!/usr/bin/env bash
# Flash and run the AtomVM harness on a real ESP32 board.
#
# Usage:
#   ./scripts/run_avm_esp32_flash.sh --base   # once: write release image
#   ./scripts/run_avm_esp32_flash.sh          # flash tests.avm + follow serial
#
# Env:
#   ESPPORT                 serial port (auto-detect if unset)
#   MAIN_AVM_OFFSET         default 0x250000 (AtomVM 0.7+)
#   MONITOR_TIMEOUT_SEC     default 45
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

MAIN_AVM_OFFSET="${MAIN_AVM_OFFSET:-0x250000}"
MONITOR_TIMEOUT_SEC="${MONITOR_TIMEOUT_SEC:-45}"

require_cmd python3

if ! command -v esptool.py >/dev/null 2>&1 && ! command -v esptool >/dev/null 2>&1; then
  echo "error: esptool.py (or esptool) required on PATH" >&2
  exit 1
fi
ESPTOOL="$(command -v esptool.py || command -v esptool)"

detect_port() {
  if [[ -n "${ESPPORT:-}" ]]; then
    echo "$ESPPORT"
    return
  fi
  local cand
  for cand in /dev/cu.usbmodem* /dev/cu.usbserial* /dev/ttyACM* /dev/ttyUSB*; do
    if [[ -e "$cand" ]]; then
      echo "$cand"
      return
    fi
  done
  echo "error: no serial port found; set ESPPORT" >&2
  exit 1
}

"$SCRIPT_DIR/fetch_atomvm.sh" esp32
PORT="$(detect_port)"
IMG="$ATOMVM_CACHE/esp32/AtomVM-esp32-${ATOMVM_VERSION}.img"

if [[ "${1:-}" == "--base" ]]; then
  FLASH_IMG_OFFSET="${FLASH_IMG_OFFSET:-0x1000}"
  echo "Flashing base image to $PORT @ $FLASH_IMG_OFFSET…"
  "$ESPTOOL" --chip esp32 --port "$PORT" write_flash "$FLASH_IMG_OFFSET" "$IMG"
  echo "Base image written."
  exit 0
fi

"$SCRIPT_DIR/pack_avm_tests.sh" --no-libs

echo "Flashing tests.avm to $PORT @ $MAIN_AVM_OFFSET…"
"$ESPTOOL" --chip esp32 --port "$PORT" write_flash "$MAIN_AVM_OFFSET" "$TESTS_AVM"

LOG="$(mktemp)"
echo "Monitoring serial for ${MONITOR_TIMEOUT_SEC}s…"
set +e
python3 - "$PORT" "$MONITOR_TIMEOUT_SEC" "$LOG" <<'PY'
import sys, time
port, timeout_s, log_path = sys.argv[1], float(sys.argv[2]), sys.argv[3]
try:
    import serial
except ImportError:
    sys.stderr.write("error: pyserial required (pip install pyserial)\n")
    sys.exit(2)

ser = serial.Serial(port, 115200, timeout=0.2)
ser.dtr = False
ser.rts = True
time.sleep(0.1)
ser.rts = False
deadline = time.time() + timeout_s
with open(log_path, "w", encoding="utf-8", errors="replace") as log:
    while time.time() < deadline:
        data = ser.read(1024)
        if data:
            text = data.decode("utf-8", errors="replace")
            sys.stdout.write(text)
            sys.stdout.flush()
            log.write(text)
            log.flush()
            if "AVM_GLEAM_TESTS_OK" in text or "AVM_GLEAM_TESTS_FAIL" in text:
                time.sleep(0.5)
                extra = ser.read(4096)
                if extra:
                    text = extra.decode("utf-8", errors="replace")
                    sys.stdout.write(text)
                    log.write(text)
                break
ser.close()
PY
status=$?
set -e

assert_ok_marker "$LOG"
exit_code=$?
rm -f "$LOG"
exit "$exit_code"
