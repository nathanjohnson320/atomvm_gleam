# atomvm_gleam

Typed Gleam wrappers for [AtomVM](https://github.com/atomvm/AtomVM)
**[`v0.7.0-beta.0`](https://github.com/atomvm/AtomVM/releases/tag/v0.7.0-beta.0)** —
peripherals, networking, crypto, and [AtomGL](https://github.com/atomvm/atomgl)
display.

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

Hardware examples live in
[`atomvm_gleam_examples`](https://github.com/nathanjohnson320/atomvm_gleam_examples).

## Supported modules

Coverage is against AtomVM `v0.7.0-beta.0` / `release-0.7` libs (`avm_esp32`,
`avm_rp2`, `avm_network`, `eavmlib`, `estdlib`), plus AtomGL and
[`atomvm_websocket_client`](https://github.com/nerves-hub/atomvm_websocket_client).

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
| `atomvm_gleam/websocket` | [`atomvm_websocket_client`](https://github.com/nerves-hub/atomvm_websocket_client) | `open` / send text\|binary / `close` |

Import as `atomvm_gleam/<module>`, e.g. `import atomvm_gleam/gpio`.

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
| `emscripten` | Browser/JS interop (`run_script`, HTML5 events, promises, tracked values) |
| `websocket` (emscripten) | Browser WebSocket NIFs in `avm_emscripten` (distinct from `atomvm_websocket_client`) |

The Emscripten/WASM platform itself is supported: `atomvm.platform()` returns
`Emscripten`, and the shared modules above work wherever the underlying NIFs
exist. Dedicated Gleam wrappers for `avm_emscripten` are not shipped yet.

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
