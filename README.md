# atomvm_gleam

Typed Gleam wrappers for [AtomVM](https://github.com/atomvm/AtomVM) **0.7**
(`release-0.7` / `v0.7.0-beta.x`) — peripherals, networking, crypto,
[AtomGL](https://github.com/atomvm/atomgl) display, and AtomVM WASM /
emscripten browser APIs.

This package targets the same major as AtomVM. A stable **0.7** hex release is
planned when AtomVM 0.7 ships; until then treat this as pre-release against the
AtomVM `release-0.7` branch.

## Requirements

- Gleam `>= 1.18.1`
- AtomVM built from `release-0.7` (or a `v0.7.0-beta.x` tag)
- Erlang/OTP for the Gleam compile toolchain (OTP 27+ recommended)

```toml
[dependencies]
atomvm_gleam = { git = "https://github.com/nathanjohnson320/atomvm_gleam.git" }
```

## Supported modules

Coverage below is against AtomVM `release-0.7` libs (`avm_esp32`, `avm_rp2`,
`avm_network`, `avm_emscripten`, `eavmlib`, `estdlib`), plus AtomGL / websocket
extras used by the badge examples.

| Gleam module | Upstream | Status |
| --- | --- | --- |
| `atomvm_gleam/gpio` | `gpio` (ESP32 + RP2) | Full public API, including Pico WL pins and `set_function` |
| `atomvm_gleam/i2c` | `i2c` | Full public API |
| `atomvm_gleam/spi` | `spi` | Full public API |
| `atomvm_gleam/uart` | `uart` | Full public API (+ `usb_serial_jtag_name`) |
| `atomvm_gleam/usb_cdc` | `usb_cdc` (ESP32 / RP2 / STM32) | Full public API |
| `atomvm_gleam/ledc` | `ledc` | Full public API (timers, channels, fade, duty/freq) |
| `atomvm_gleam/adc` | `esp_adc` | Full public API (resource + pin convenience paths) |
| `atomvm_gleam/esp_dac` | `esp_dac` | Public oneshot API (`new_channel`, output, delete) |
| `atomvm_gleam/esp` | `esp` | Broad coverage (NVS, sleep, partitions, RTC, mount, WDT, MAC) |
| `atomvm_gleam/pico` | `pico` | Full public API (CYW43 GPIO + RTC) |
| `atomvm_gleam/network` | `network` | STA/AP start, wait helpers, scan, RSSI/status, SNTP/mDNS config |
| `atomvm_gleam/http` | `ahttp_client` | Full public API (connect/request/stream/recv/close) |
| `atomvm_gleam/http_server` | `http_server` | Full public API |
| `atomvm_gleam/mdns` | `mdns` | `start_link` / `stop` (responder lifecycle) |
| `atomvm_gleam/ssl` | `ssl` | Client API (`start`/`stop`/`connect`/`send`/`recv`/`close`) |
| `atomvm_gleam/console` | `console` | `start` / `puts` / `print` / `print_err` / `flush` |
| `atomvm_gleam/atomvm` | `atomvm` | Platform, AVM packs, `random`, POSIX I/O, `subprocess` |
| `atomvm_gleam/crypto` | `crypto` | Hash, MAC, AEAD, PBKDF2, ECDH/EdDH, sign/verify, `strong_rand_bytes` |
| `atomvm_gleam/json` | `json` | `encode/1` and `decode/1` |
| `atomvm_gleam/display` | [AtomGL](https://github.com/atomvm/atomgl) `display` port | `open` / `update` / font register/deregister |
| `atomvm_gleam/websocket` | [`atomvm_websocket_client`](https://github.com/nerves-hub/atomvm_websocket_client) | ESP-IDF port: `open` / send text\|binary / `close` |
| `atomvm_gleam/emscripten` | [`avm_emscripten`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html) `emscripten` | JS interop: `run_script`, tracked objects, promise resolve/reject (HTML5 callbacks still pending — [#42](https://github.com/nathanjohnson320/atomvm_gleam/issues/42)) |
| `atomvm_gleam/emscripten_websocket` | [`avm_emscripten`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html) `websocket` | Browser WebSocket NIF (full public API); Gleam path differs because `websocket` is taken by the ESP client |

Import as `atomvm_gleam/<module>`, e.g. `import atomvm_gleam/gpio`.

### Two WebSocket modules

| Gleam module | Platform | Upstream |
| --- | --- | --- |
| `atomvm_gleam/websocket` | ESP-IDF (and images that include the port driver) | [`atomvm_websocket_client`](https://github.com/nerves-hub/atomvm_websocket_client) |
| `atomvm_gleam/emscripten_websocket` | Emscripten / browser only | AtomVM `avm_emscripten` Erlang module `websocket` |

They are not interchangeable: different message shapes, APIs, and platforms.
Check `atomvm.platform()` (or `emscripten_websocket.is_supported()`) before calling
the browser NIF on mixed-target builds.

## AtomVM WASM / emscripten

AtomVM can run as WebAssembly in the browser or under Node. Gleam code for that
target is still compiled for the **Erlang BEAM** and loaded by AtomVM WASM —
use `@external(erlang, ...)` FFI as elsewhere in this package. Gleam’s JavaScript
backend is a different toolchain and is not used here.

Upstream docs (prefer `release-0.7`):

- [Getting Started — WebAssembly](https://doc.atomvm.org/release-0.7/getting-started-guide.html#getting-started-with-atomvm-webassembly)
- [Build instructions — emscripten](https://doc.atomvm.org/release-0.7/build-instructions.html#building-for-emscripten)
- API: [`emscripten`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html),
  [`websocket`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html)
  (under `avm_emscripten`)

Browser hosting note (high level): AtomVM’s web build uses `SharedArrayBuffer`,
so pages must be served from localhost or HTTPS with COOP/COEP headers
(`Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp`). See the AtomVM getting-started
guide for hosting options; this package does not document a full deploy tutorial.

## Known gaps vs AtomVM 0.7

Still useful upstream APIs that are **not** wrapped (or only partially):

| Area | Missing |
| --- | --- |
| `esp` | `partition_mmap/3`, `timer_get_time/0`, legacy `nvs_set_binary` / arity-1 NVS helpers, `sleep_enable_ext1_wakeup/2` |
| `atomvm` | `posix_tcgetattr` / `posix_tcsetattr` / `posix_tcflush`, `get_creation/0` (deprecated `rand_bytes/1` intentionally omitted — use `crypto.strong_rand_bytes`) |
| `crypto` | Streaming cipher `crypto_init` / `crypto_update` / `crypto_final` |
| `json` | OTP-style `encode/2`, `decode/3`, `decode_start` / `decode_continue`, and the fine-grained encode helpers |
| `mdns` | DNS parse/serialize helpers (`parse_dns_message`, etc.) |
| `console` | Port-handle overloads (`puts/2`, `flush/1`) |
| `emscripten` | HTML5 event register/unregister callbacks (keyboard, mouse, touch, …) — tracked in [#42](https://github.com/nathanjohnson320/atomvm_gleam/issues/42) |

Intentionally **out of scope** for this package:

- OTP/estdlib staples (`gen_server`, `gen_tcp`, `lists`, …) — use Gleam / `gleam_erlang`
- Platform-internal HALs (`gpio_hal`, `i2c_hal`, …), alisp, JIT

PRs welcome for the gaps above.

## Development

```sh
gleam format
gleam build
```

Agent / contribution conventions: [`AGENTS.md`](./AGENTS.md).
