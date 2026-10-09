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
```

See [`AGENTS.md`](./AGENTS.md) for contribution conventions.
