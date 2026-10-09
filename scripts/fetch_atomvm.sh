#!/usr/bin/env bash
# Download / cache AtomVM 0.7.0-beta.0 artifacts for test runners.
#
# Usage:
#   ./scripts/fetch_atomvm.sh packbeam
#   ./scripts/fetch_atomvm.sh wasm
#   ./scripts/fetch_atomvm.sh esp32
#   ./scripts/fetch_atomvm.sh pico
#   ./scripts/fetch_atomvm.sh qemu
#   ./scripts/fetch_atomvm.sh libs
#   ./scripts/fetch_atomvm.sh unix
#   ./scripts/fetch_atomvm.sh all
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

fetch_packbeam() {
  if [[ -x "$PACKBEAM_BIN" ]]; then
    echo "packbeam ready: $PACKBEAM_BIN"
    return 0
  fi
  require_cmd rebar3
  require_cmd git
  local src="$ATOMVM_CACHE/src/atomvm_packbeam"
  if [[ ! -d "$src/.git" ]]; then
    rm -rf "$src"
    mkdir -p "$(dirname "$src")"
    git clone --depth 1 https://github.com/atomvm/atomvm_packbeam.git "$src"
  fi
  (
    cd "$src"
    rebar3 escriptize
  )
  cp "$src/_build/default/bin/packbeam" "$PACKBEAM_BIN"
  chmod +x "$PACKBEAM_BIN"
  echo "packbeam installed: $PACKBEAM_BIN"
}

fetch_wasm() {
  # Release assets keep the leading `v` (AtomVM-node-v0.7.0-beta.0.mjs).
  local base="AtomVM-node-${ATOMVM_VERSION}"
  download "$RELEASE_BASE/${base}.mjs" "$ATOMVM_CACHE/wasm/AtomVM.mjs"
  download "$RELEASE_BASE/${base}.wasm" "$ATOMVM_CACHE/wasm/AtomVM.wasm"
  # Loader resolves sibling `${base}.wasm` next to the .mjs.
  cp "$ATOMVM_CACHE/wasm/AtomVM.wasm" "$ATOMVM_CACHE/wasm/${base}.wasm"
  echo "wasm ready under $ATOMVM_CACHE/wasm"
}

fetch_esp32() {
  local img="AtomVM-esp32-${ATOMVM_VERSION}.img"
  download "$RELEASE_BASE/$img" "$ATOMVM_CACHE/esp32/$img"
  download "$RELEASE_BASE/$img.sha256" "$ATOMVM_CACHE/esp32/$img.sha256" || true
  (
    cd "$ATOMVM_CACHE/esp32"
    if [[ -f "$img.sha256" ]]; then
      shasum -a 256 -c "$img.sha256"
    fi
  )
  echo "esp32 image ready: $ATOMVM_CACHE/esp32/$img"
}

ensure_arm_none_eabi() {
  if command -v arm-none-eabi-gcc >/dev/null 2>&1; then
    return 0
  fi
  local tc_root="$ROOT/.atomvm/toolchains"
  local existing
  existing="$(find "$tc_root" -type f -name arm-none-eabi-gcc 2>/dev/null | head -n 1 || true)"
  if [[ -n "$existing" ]]; then
    export PATH="$(dirname "$existing"):$PATH"
    return 0
  fi

  local os arch host url dist
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os/$arch" in
    Darwin/arm64|Darwin/aarch64) host="darwin-arm64" ;;
    Darwin/x86_64) host="darwin-x86_64" ;;
    Linux/x86_64|Linux/amd64) host="x86_64" ;;
    Linux/aarch64|Linux/arm64) host="aarch64" ;;
    *)
      echo "error: no portable arm-none-eabi toolchain for $os/$arch" >&2
      echo "Install gcc-arm-none-eabi and retry." >&2
      exit 1
      ;;
  esac

  # Arm GNU Toolchain 14.2 Rel1 (no sudo; extracted under .atomvm/toolchains).
  if [[ "$os" == "Darwin" ]]; then
    dist="arm-gnu-toolchain-14.2.rel1-${host}-arm-none-eabi.tar.xz"
    url="https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/${dist}"
  else
    dist="arm-gnu-toolchain-14.2.rel1-${host}-arm-none-eabi.tar.xz"
    url="https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/${dist}"
  fi

  mkdir -p "$tc_root"
  local tarball="$tc_root/$dist"
  download "$url" "$tarball"
  echo "Extracting ARM toolchain…"
  tar -xJf "$tarball" -C "$tc_root"
  existing="$(find "$tc_root" -type f -name arm-none-eabi-gcc | head -n 1 || true)"
  if [[ -z "$existing" ]]; then
    echo "error: arm-none-eabi-gcc missing after extract" >&2
    exit 1
  fi
  export PATH="$(dirname "$existing"):$PATH"
  echo "arm-none-eabi-gcc ready: $existing"
}

fetch_pico_bootrom() {
  local rom_elf="$ATOMVM_CACHE/pico/b1.elf"
  local rom_bin="$ATOMVM_CACHE/pico/bootrom.bin"
  download \
    "https://github.com/raspberrypi/pico-bootrom/releases/download/b1/b1.elf" \
    "$rom_elf"
  if [[ ! -f "$rom_bin" ]]; then
    require_cmd python3
    python3 - "$rom_elf" "$rom_bin" <<'PY'
import sys
elf, dest = sys.argv[1], sys.argv[2]
data = open(elf, "rb").read()
open(dest, "wb").write(data[0x10000:0x14000])
print(f"wrote {dest} ({len(data[0x10000:0x14000])} bytes)")
PY
  fi
  echo "pico bootrom ready: $rom_bin"
}

fetch_pico() {
  # Release Pico-W UF2s hang under rp2040js (CYW43 / SMP). Build a plain Pico
  # image with SMP disabled — same approach as AtomVM's own pico CI tests.
  local emu_uf2="$ATOMVM_CACHE/pico/AtomVM-pico-emu-combined.uf2"
  fetch_pico_bootrom
  if [[ -f "$emu_uf2" ]]; then
    echo "pico emu uf2 ready: $emu_uf2"
    return 0
  fi

  require_cmd cmake
  require_cmd git
  require_cmd rebar3
  ensure_arm_none_eabi
  if ! command -v ninja >/dev/null 2>&1 && ! command -v make >/dev/null 2>&1; then
    echo "error: need ninja or make to build Pico AtomVM" >&2
    exit 1
  fi
  local gen=()
  local build_cmd
  if command -v ninja >/dev/null 2>&1; then
    gen=(-G Ninja)
    build_cmd=(cmake --build)
  else
    build_cmd=(cmake --build)
  fi

  local src="$ATOMVM_CACHE/src/AtomVM"
  if [[ ! -d "$src/.git" ]]; then
    rm -rf "$src"
    mkdir -p "$(dirname "$src")"
    git clone --depth 1 --branch "$ATOMVM_VERSION" \
      https://github.com/atomvm/AtomVM.git "$src"
  fi

  echo "Building atomvmlib-rp2 + uf2tool…"
  local host_build="$ATOMVM_CACHE/src/AtomVM-build-pico-host"
  mkdir -p "$host_build"
  (
    cd "$host_build"
    cmake "$src" "${gen[@]}" -DPACKBEAM_PATH="$PACKBEAM_BIN"
    "${build_cmd[@]}" . --target atomvmlib-rp2 -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
    "${build_cmd[@]}" . --target UF2Tool -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
  )
  fetch_packbeam

  local lib_uf2
  lib_uf2="$(find "$host_build" -name 'atomvmlib-rp2-pico.uf2' | head -n 1 || true)"
  if [[ -z "$lib_uf2" ]]; then
    lib_uf2="$(find "$host_build" -name 'atomvmlib-rp2*.uf2' | head -n 1 || true)"
  fi
  if [[ -z "$lib_uf2" ]]; then
    echo "error: atomvmlib-rp2 UF2 not produced under $host_build" >&2
    exit 1
  fi

  local uf2tool
  uf2tool="$(find "$host_build" -type f -name uf2tool | head -n 1 || true)"
  if [[ -z "$uf2tool" ]]; then
    echo "error: uf2tool not found under $host_build" >&2
    exit 1
  fi
  chmod +x "$uf2tool"

  echo "Building AtomVM for pico (SMP off)…"
  local pico_build="$ATOMVM_CACHE/src/AtomVM-build-pico-emu"
  mkdir -p "$pico_build"
  # Prefer CMake < 4 if we vendored one (Homebrew 4.x breaks some pico-sdk checks).
  local cmake_bin
  cmake_bin="$(find "$ROOT/.atomvm/toolchains" -type f -path '*/bin/cmake' 2>/dev/null | head -n 1 || true)"
  if [[ -n "$cmake_bin" ]]; then
    export PATH="$(dirname "$cmake_bin"):$PATH"
  fi
  (
    cd "$pico_build"
    # First configure fetches pico-sdk; may fail on docs/CMakeLists DOXYGEN quirk.
    # USB CDC port driver forces stdio onto UART (needed for rp2040js uart[0]).
    local pico_cmake_flags=(
      -DPICO_BOARD=pico
      -DAVM_DISABLE_SMP=ON
      -DPICO_BUILD_DOCS=OFF
      -DAVM_USB_CDC_PORT_DRIVER_ENABLED=ON
      -DAVM_WAIT_BOOTSEL_ON_EXIT=OFF
    )
    cmake "$src/src/platforms/rp2" "${gen[@]}" "${pico_cmake_flags[@]}" || true
    local sdk_docs
    sdk_docs="$(find "$pico_build/_deps" -path '*/pico_sdk*/docs/CMakeLists.txt' | head -n 1 || true)"
    if [[ -n "$sdk_docs" ]]; then
      # `${DOXYGEN_FOUND}` expands empty when Doxygen is missing and breaks `if(... AND)`.
      if grep -q 'AND \${DOXYGEN_FOUND}' "$sdk_docs"; then
        sed -i.bak 's/AND \${DOXYGEN_FOUND}/AND DOXYGEN_FOUND/' "$sdk_docs"
      fi
    fi
    cmake "$src/src/platforms/rp2" "${gen[@]}" "${pico_cmake_flags[@]}"
    "${build_cmd[@]}" . --target AtomVM -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
  )
  local vm_uf2
  vm_uf2="$(find "$pico_build" -name 'AtomVM.uf2' | head -n 1 || true)"
  if [[ -z "$vm_uf2" ]]; then
    echo "error: AtomVM.uf2 not produced under $pico_build" >&2
    exit 1
  fi

  echo "Combining VM + atomvmlib → $emu_uf2"
  "$uf2tool" join -o "$emu_uf2" "$vm_uf2" "$lib_uf2"
  cp "$vm_uf2" "$ATOMVM_CACHE/pico/AtomVM-pico-emu.uf2"
  cp "$lib_uf2" "$ATOMVM_CACHE/pico/atomvmlib-rp2-pico.uf2"
  echo "pico emu uf2 ready: $emu_uf2"
}

fetch_qemu() {
  if [[ -n "${QEMU_BIN:-}" && -x "$QEMU_BIN" && "$QEMU_BIN" != "$ATOMVM_CACHE/bin/qemu-system-xtensa" ]]; then
    echo "qemu ready: $QEMU_BIN"
    return 0
  fi
  if command -v qemu-system-xtensa >/dev/null 2>&1; then
    local existing
    existing="$(command -v qemu-system-xtensa)"
    # Prefer a cached Espressif build over stock Homebrew qemu (no `esp32` machine).
    if [[ -x "$ATOMVM_CACHE/bin/qemu-system-xtensa" ]]; then
      echo "qemu ready: $ATOMVM_CACHE/bin/qemu-system-xtensa"
      return 0
    fi
    ln -sfn "$existing" "$ATOMVM_CACHE/bin/qemu-system-xtensa"
    echo "qemu linked from PATH: $existing"
    return 0
  fi
  if [[ -x "$ATOMVM_CACHE/bin/qemu-system-xtensa" ]]; then
    echo "qemu ready: $ATOMVM_CACHE/bin/qemu-system-xtensa"
    return 0
  fi

  local os arch host dist
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os/$arch" in
    Darwin/arm64|Darwin/aarch64) host="aarch64-apple-darwin" ;;
    Darwin/x86_64) host="x86_64-apple-darwin" ;;
    Linux/x86_64|Linux/amd64) host="x86_64-linux-gnu" ;;
    Linux/aarch64|Linux/arm64) host="aarch64-linux-gnu" ;;
    *)
      echo "error: no Espressif QEMU binary for $os/$arch" >&2
      echo "Install Espressif qemu-system-xtensa and put it on PATH, or set QEMU_BIN." >&2
      exit 1
      ;;
  esac

  dist="qemu-xtensa-softmmu-${ESPRESSIF_QEMU_BUILD}-${host}.tar.xz"
  local url="https://github.com/espressif/qemu/releases/download/${ESPRESSIF_QEMU_VER}/${dist}"
  local tarball="$ATOMVM_CACHE/qemu/$dist"
  download "$url" "$tarball"

  local extract="$ATOMVM_CACHE/qemu/$host"
  rm -rf "$extract"
  mkdir -p "$extract"
  tar -xJf "$tarball" -C "$extract"

  local found
  found="$(find "$extract" -type f -name qemu-system-xtensa | head -n 1 || true)"
  if [[ -z "$found" ]]; then
    echo "error: qemu-system-xtensa not found in $dist" >&2
    exit 1
  fi
  ln -sfn "$found" "$ATOMVM_CACHE/bin/qemu-system-xtensa"
  chmod +x "$found"
  echo "qemu ready: $ATOMVM_CACHE/bin/qemu-system-xtensa"
}

fetch_libs() {
  # atomvmlib.avm is not a release asset; build it from the matching tag.
  local lib="$ATOMVM_CACHE/libs/atomvmlib.avm"
  if [[ -f "$lib" ]]; then
    echo "atomvmlib ready: $lib"
    return 0
  fi
  require_cmd git
  require_cmd cmake
  require_cmd make
  fetch_packbeam
  local src="$ATOMVM_CACHE/src/AtomVM"
  if [[ ! -d "$src/.git" ]]; then
    rm -rf "$src"
    mkdir -p "$(dirname "$src")"
    git clone --depth 1 --branch "$ATOMVM_VERSION" \
      https://github.com/atomvm/AtomVM.git "$src"
  fi
  local build="$ATOMVM_CACHE/src/AtomVM-build-libs"
  mkdir -p "$build"
  (
    cd "$build"
    cmake "$src" \
      -DAVM_BUILD_RUNTIME_ONLY=OFF \
      -DPACKBEAM_PATH="$PACKBEAM_BIN"
    if ! cmake --build . --target atomvmlib -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"; then
      cmake --build . -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
    fi
  )
  local found
  found="$(find "$build" -name 'atomvmlib.avm' | head -n 1 || true)"
  if [[ -z "$found" ]]; then
    echo "error: atomvmlib.avm not produced under $build" >&2
    exit 1
  fi
  cp "$found" "$lib"
  echo "atomvmlib ready: $lib"
}

# Build Mbed TLS 3.6+ into $MBEDTLS_PREFIX (ECDSA needs > 3.6.1; Ubuntu apt is 2.28).
ensure_mbedtls() {
  local stamp="$MBEDTLS_PREFIX/.atomvm_mbedtls_version"
  local shlib="libmbedcrypto.so"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    shlib="libmbedcrypto.dylib"
  fi
  if [[ -f "$stamp" && "$(cat "$stamp")" == "$MBEDTLS_VERSION" \
      && -f "$MBEDTLS_PREFIX/include/mbedtls/version.h" \
      && -e "$MBEDTLS_PREFIX/lib/$shlib" ]]; then
    echo "mbedtls ready: $MBEDTLS_PREFIX ($MBEDTLS_VERSION)"
    return 0
  fi

  echo "Building Mbed TLS $MBEDTLS_VERSION → $MBEDTLS_PREFIX…"
  require_cmd git
  require_cmd cmake
  require_cmd make
  local src="$ATOMVM_CACHE/src/mbedtls"
  local build="$ATOMVM_CACHE/src/mbedtls-build"
  rm -rf "$MBEDTLS_PREFIX" "$build"
  if [[ ! -d "$src/.git" ]] || [[ "$(git -C "$src" describe --tags --exact-match 2>/dev/null || true)" != "$MBEDTLS_VERSION" ]]; then
    rm -rf "$src"
    mkdir -p "$(dirname "$src")"
    git clone --depth 1 --branch "$MBEDTLS_VERSION" \
      https://github.com/Mbed-TLS/mbedtls.git "$src"
    git -C "$src" submodule update --init --recursive --depth 1
  fi
  mkdir -p "$build"
  (
    cd "$build"
    # MBEDTLS_FATAL_WARNINGS=OFF: AppleClang 21+ errors on TLS 1.3 label
    # arrays; AtomVM's FetchMbedTLS.cmake suppresses the same diagnostics.
    cmake "$src" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$MBEDTLS_PREFIX" \
      -DMBEDTLS_FATAL_WARNINGS=OFF \
      -DUSE_SHARED_MBEDTLS_LIBRARY=On \
      -DUSE_STATIC_MBEDTLS_LIBRARY=Off \
      -DENABLE_TESTING=OFF \
      -DENABLE_PROGRAMS=OFF
    cmake --build . -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
    cmake --install .
  )
  printf '%s\n' "$MBEDTLS_VERSION" >"$stamp"
  echo "mbedtls ready: $MBEDTLS_PREFIX ($MBEDTLS_VERSION)"
}

fetch_unix() {
  if [[ -n "${ATOMVM_BIN:-}" && -x "$ATOMVM_BIN" ]]; then
    ln -sfn "$ATOMVM_BIN" "$ATOMVM_CACHE/unix/AtomVM"
    echo "unix AtomVM linked from ATOMVM_BIN=$ATOMVM_BIN"
    fetch_libs
    return 0
  fi
  if command -v AtomVM >/dev/null 2>&1; then
    ln -sfn "$(command -v AtomVM)" "$ATOMVM_CACHE/unix/AtomVM"
    echo "unix AtomVM linked from PATH"
    fetch_libs
    return 0
  fi

  local stamp="$ATOMVM_CACHE/unix/.built-with-mbedtls"
  if [[ -x "$ATOMVM_CACHE/unix/AtomVM" && -f "$stamp" \
      && "$(cat "$stamp")" == "$MBEDTLS_VERSION" ]]; then
    echo "unix AtomVM ready: $ATOMVM_CACHE/unix/AtomVM (mbedtls $MBEDTLS_VERSION)"
    fetch_libs
    return 0
  fi

  echo "No AtomVM binary on PATH; building generic_unix from $ATOMVM_VERSION…"
  require_cmd git
  require_cmd cmake
  require_cmd make
  fetch_packbeam
  ensure_mbedtls
  local src="$ATOMVM_CACHE/src/AtomVM"
  if [[ ! -d "$src/.git" ]]; then
    rm -rf "$src"
    mkdir -p "$(dirname "$src")"
    git clone --depth 1 --branch "$ATOMVM_VERSION" \
      https://github.com/atomvm/AtomVM.git "$src"
  fi
  local build="$ATOMVM_CACHE/src/AtomVM-build-unix"
  # Force a clean configure so a prior system-mbedtls build cannot linger.
  rm -rf "$build"
  mkdir -p "$build"
  (
    cd "$build"
    cmake "$src" \
      -DPACKBEAM_PATH="$PACKBEAM_BIN" \
      -DMBEDTLS_ROOT_DIR="$MBEDTLS_PREFIX"
    cmake --build . -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
  )
  local bin
  bin="$(find "$build" -type f -name AtomVM | head -n 1 || true)"
  if [[ -z "$bin" ]]; then
    echo "error: AtomVM binary not found after build" >&2
    exit 1
  fi
  cp "$bin" "$ATOMVM_CACHE/unix/AtomVM"
  chmod +x "$ATOMVM_CACHE/unix/AtomVM"
  printf '%s\n' "$MBEDTLS_VERSION" >"$stamp"
  local lib
  lib="$(find "$build" -name 'atomvmlib.avm' | head -n 1 || true)"
  if [[ -n "$lib" ]]; then
    cp "$lib" "$ATOMVM_CACHE/libs/atomvmlib.avm"
  else
    fetch_libs
  fi
  echo "unix AtomVM ready: $ATOMVM_CACHE/unix/AtomVM"
}

usage() {
  sed -n '2,12p' "$0"
}

target="${1:-}"
case "$target" in
  packbeam) fetch_packbeam ;;
  wasm) fetch_wasm ;;
  esp32) fetch_esp32 ;;
  pico) fetch_pico ;;
  qemu) fetch_qemu ;;
  libs) fetch_libs ;;
  unix) fetch_unix ;;
  all)
    fetch_packbeam
    fetch_wasm
    fetch_esp32
    fetch_pico
    fetch_qemu
    fetch_libs
    ;;
  *)
    usage
    exit 1
    ;;
esac
