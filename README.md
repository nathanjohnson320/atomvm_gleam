# atomvm_gleam

Typed Gleam wrappers for [AtomVM](https://github.com/atomvm/AtomVM)
[`v0.7.0-beta.0`](https://github.com/atomvm/AtomVM/releases/tag/v0.7.0-beta.0):
peripherals, networking, crypto, and [AtomGL](https://github.com/atomvm/atomgl).

Package version tracks the matching AtomVM pre-release. APIs may still shift
until AtomVM ships a stable 0.7.0.

## Requirements

- Gleam `>= 1.18.1`
- Erlang/OTP 26+ (OTP 27+ recommended)
- Some tool to flash atomVM to device (or run via wasm in hosted file)

```toml
[dependencies]
atomvm_gleam = ">= 0.7.0-beta.0-1 and < 0.8.0"
```

Import as `atomvm_gleam/<module>`, e.g. `import atomvm_gleam/gpio`.

## Documentation

- [HexDocs](https://atomvm-gleam.hexdocs.pm)

## Known gaps

- `atomvm.rand_bytes/1` omitted (deprecated; use `crypto.strong_rand_bytes`)
- `json` custom OTP encoder funs / decoder callback maps are not wrapped;
  default encoder/decoders are provided

Out of scope: OTP/estdlib staples (`gen_server`, `gen_tcp`, …), platform-internal
HALs, alisp, JIT, `esp32devmode`, `epmd`, `port`, `logger_manager`,
`timer_manager`, `timestamp_util`.

## Development

```sh
gleam format
gleam build
gleam test
```

See [`AGENTS.md`](./AGENTS.md) for contribution conventions.

## Testing

- **Host (normal functions):** `gleam test`
- **Generic Unix:** `./scripts/run_avm_unix.sh`
- **WASM / emscripten:** `./scripts/run_avm_wasm.sh`
- **ESP32 (QEMU):** `./scripts/run_avm_esp32_qemu.sh`
- **ESP32 (board):** `./scripts/run_avm_esp32_flash.sh --base` once, then `./scripts/run_avm_esp32_flash.sh`
- **Pico (rp2040js):** `./scripts/run_avm_pico_rp2040js.sh` (Node 20+)

Each AtomVM runner re-packs `build/tests.avm` for its target (ESP32 / Pico omit
host `atomvmlib` so platform modules are not shadowed) and prints
`AVM_GLEAM_TESTS_OK` on success.
