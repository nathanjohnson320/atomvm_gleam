# atomvm_gleam

Typed Gleam wrappers for [AtomVM](https://github.com/atomvm/AtomVM)
**[`v0.7.0-beta.0`](https://github.com/atomvm/AtomVM/releases/tag/v0.7.0-beta.0)** —
peripherals, networking, crypto, [AtomGL](https://github.com/atomvm/atomgl)
display, and AtomVM WASM / emscripten browser APIs.

Package version tracks the matching AtomVM pre-release (`0.7.0-beta.0`). APIs
may still shift until AtomVM ships a stable 0.7.0.

## Requirements

- Gleam `>= 1.18.1`
- AtomVM [`v0.7.0-beta.0`](https://github.com/atomvm/AtomVM/releases/tag/v0.7.0-beta.0)
  (or `release-0.7` at a compatible revision)
- Erlang/OTP 26+ for the Gleam compile toolchain (OTP 27+ recommended)

```toml
[dependencies]
atomvm_gleam = ">= 0.7.0-beta.0 and < 0.8.0"
```

## Supported modules

Coverage against AtomVM `v0.7.0-beta.0` / `release-0.7` libs (`avm_esp32`,
`avm_rp2`, `avm_network`, `avm_emscripten`, `eavmlib`, `estdlib`), plus AtomGL
and [`atomvm_websocket_client`](https://github.com/nerves-hub/atomvm_websocket_client).

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
| `atomvm_gleam/esp` | `esp` | Full public API (NVS, sleep, partitions incl. mmap, RTC, mount, WDT, MAC, `timer_get_time`) |
| `atomvm_gleam/pico` | `pico` | Full public API (CYW43 GPIO + RTC) |
| `atomvm_gleam/network` | `network` | Full public API (STA/AP, wait helpers, scan, RSSI/status, SNTP/mDNS config) |
| `atomvm_gleam/http` | `ahttp_client` | Full public API (connect/request/stream/recv/close) |
| `atomvm_gleam/http_server` | `http_server` | Full public API |
| `atomvm_gleam/mdns` | `mdns` | Responder lifecycle + DNS parse/serialize helpers |
| `atomvm_gleam/ssl` | `ssl` | Client API (`start`/`stop`/`connect`/`send`/`recv`/`close`) |
| `atomvm_gleam/console` | `console` | Full public API (`start`, `puts`/`puts_to`, `print`/`print_err`, `flush`/`flush_handle`) |
| `atomvm_gleam/atomvm` | `atomvm` | Platform, AVM packs, `random`, POSIX I/O (incl. termios), `subprocess`, `get_creation` |
| `atomvm_gleam/avm_pubsub` | `avm_pubsub` | Full public API (`start`/`start_named`, `publish`, `sub`/`unsub`) |
| `atomvm_gleam/crypto` | `crypto` | Hash, MAC, AEAD, streaming cipher, PBKDF2, ECDH/EdDH, sign/verify, `strong_rand_bytes` |
| `atomvm_gleam/json` | `json` | `encode`/`decode` (+ `/2`/`/3`), streaming decode, fine-grained encode helpers (default encoder/decoders) |
| `atomvm_gleam/display` | [AtomGL](https://github.com/atomvm/atomgl) `display` port | `open` / `update` / font register/deregister |
| `atomvm_gleam/websocket` | [`atomvm_websocket_client`](https://github.com/nerves-hub/atomvm_websocket_client) | ESP-IDF port: `open` / send text\|binary / `close` |
| `atomvm_gleam/emscripten` | [`avm_emscripten`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html) `emscripten` | JS interop + HTML5 callbacks (`register_*` / `register_*_with` / `register_*_with_user_data`) |
| `atomvm_gleam/emscripten_websocket` | [`avm_emscripten`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html) `websocket` | Browser WebSocket NIF (full public API) |

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

Public AtomVM-facing modules targeted by this package are wrapped. Remaining
intentional omissions:

| Area | Notes |
| --- | --- |
| `atomvm` | Deprecated `rand_bytes/1` omitted — use `crypto.strong_rand_bytes` |
| `json` | Custom OTP encoder funs / custom decoder callback maps — not expressible cleanly in Gleam; default encoder/decoders are provided |

Intentionally **out of scope** for this package:

- OTP/estdlib staples (`gen_server`, `gen_tcp`, `lists`, …) — use Gleam / `gleam_erlang`
- Platform-internal HALs (`gpio_hal`, `i2c_hal`, …), alisp, JIT, `esp32devmode`, `epmd`

## Development

```sh
gleam format
gleam build
```

Agent / contribution conventions: [`AGENTS.md`](./AGENTS.md).
