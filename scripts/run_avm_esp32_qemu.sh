#!/usr/bin/env bash
# Run the AtomVM harness under Espressif QEMU (ESP32).
# Flash layout: release .img @ 0x1000, tests.avm @ main.avm (0x250000), 4MB image.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

FLASH_IMG_OFFSET="${FLASH_IMG_OFFSET:-0x1000}"
MAIN_AVM_OFFSET="${MAIN_AVM_OFFSET:-0x250000}"
FLASH_SIZE_BYTES="${FLASH_SIZE_BYTES:-$((4 * 1024 * 1024))}"
QEMU_TIMEOUT_SEC="${QEMU_TIMEOUT_SEC:-90}"

require_cmd python3

"$SCRIPT_DIR/fetch_atomvm.sh" qemu
"$SCRIPT_DIR/fetch_atomvm.sh" esp32

if [[ ! -x "$QEMU_BIN" ]]; then
  if command -v qemu-system-xtensa >/dev/null 2>&1; then
    QEMU_BIN="$(command -v qemu-system-xtensa)"
  else
    echo "error: qemu-system-xtensa not found after fetch" >&2
    exit 1
  fi
fi

# Always re-pack without host atomvmlib so unix gpio/crypto beams cannot shadow
# the ESP32 firmware modules.
"$SCRIPT_DIR/pack_avm_tests.sh" --no-libs

IMG_SRC="$ATOMVM_CACHE/esp32/AtomVM-esp32-${ATOMVM_VERSION}.img"
WORK="$ATOMVM_CACHE/esp32/qemu-work"
mkdir -p "$WORK"
IMG="$WORK/flash.img"

python3 - "$IMG_SRC" "$IMG" "$TESTS_AVM" "$FLASH_IMG_OFFSET" "$MAIN_AVM_OFFSET" "$FLASH_SIZE_BYTES" <<'PY'
import sys

src, dest, avm_path, img_off_s, avm_off_s, size_s = sys.argv[1:7]
img_off = int(img_off_s, 0)
avm_off = int(avm_off_s, 0)
flash_size = int(size_s, 0)

with open(src, "rb") as f:
    release = f.read()
with open(avm_path, "rb") as f:
    avm = f.read()

if img_off + len(release) > flash_size:
    raise SystemExit("release image does not fit in flash")
if avm_off + len(avm) > flash_size:
    raise SystemExit(
        f"tests.avm ({len(avm)} bytes) does not fit at {hex(avm_off)}"
    )

buf = bytearray(b"\xff" * flash_size)
buf[img_off : img_off + len(release)] = release
buf[avm_off : avm_off + len(avm)] = avm

if buf[0x1000] != 0xE9:
    raise SystemExit(
        f"bootloader magic missing at 0x1000 (got {hex(buf[0x1000])})"
    )
if buf[0x8000:0x8002] != b"\xaaP":
    raise SystemExit("partition table magic missing at 0x8000")

with open(dest, "wb") as f:
    f.write(buf)

print(
    f"flash {flash_size} bytes: release@{hex(img_off)} "
    f"({len(release)} bytes), tests.avm@{hex(avm_off)} ({len(avm)} bytes)"
)
PY

LOG="$WORK/qemu.log"
rm -f "$LOG"

echo "Booting QEMU ($QEMU_BIN, timeout ${QEMU_TIMEOUT_SEC}s)…"
python3 - "$QEMU_TIMEOUT_SEC" "$LOG" "$IMG" "$QEMU_BIN" <<'PY'
import subprocess, sys, time, signal

timeout_s, log_path, img, qemu = float(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
cmd = [
    qemu,
    "-nographic",
    "-machine",
    "esp32",
    "-drive",
    f"file={img},if=mtd,format=raw",
    "-global",
    "driver=timer.esp32.timg,property=wdt_disable,value=true",
]
with open(log_path, "wb") as log:
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    deadline = time.time() + timeout_s
    while time.time() < deadline and proc.poll() is None:
        try:
            text = open(log_path, "r", encoding="utf-8", errors="replace").read()
        except OSError:
            text = ""
        if "AVM_GLEAM_TESTS_OK" in text or "AVM_GLEAM_TESTS_FAIL" in text:
            time.sleep(0.5)
            break
        time.sleep(0.25)
    if proc.poll() is None:
        proc.send_signal(signal.SIGTERM)
        try:
            proc.wait(timeout=5)
        except Exception:
            proc.kill()
sys.exit(0)
PY

echo "----- qemu log (tail) -----"
tail -n 120 "$LOG" || true

assert_ok_marker "$LOG"
