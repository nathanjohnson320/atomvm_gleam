# Agent instructions for atomvm_gleam

Typed Gleam wrappers for AtomVM **0.7** (`v0.7.0-beta.0-1` / `release-0.7`), not 0.6.
Package version matches that AtomVM pre-release (`0.7.0-beta.0-1`).

Upstream layout changed in 0.7: platform APIs live under `libs/avm_esp32`, `libs/avm_rp2`, `libs/avm_network`, `libs/avm_emscripten`, etc. Prefer those sources and `doc.atomvm.org/release-0.7` over old monolithic `eavmlib` docs. AtomVM WASM still runs BEAM - keep `@external(erlang, ...)` (not Gleam’s JS backend).

## File layout

| Kind | Path |
| --- | --- |
| Gleam API | `src/atomvm_gleam/<module>.gleam` |
| Erlang FFI | `src/atomvm_gleam_<module>_ffi.erl` |

Keep one Gleam module ↔ one FFI module. Do not invent alternate naming.

## Gleam style

- Module doc with upstream source + docs links (prefer `release-0.7`).
- Opaque handle types for ports/resources (`pub type Bus`, `pub type Gpio`, …).
- Shared error shape unless the upstream API needs more:

```gleam
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}
```

- Always provide `error_to_string(Error) -> String`.
- Public functions return `Result(_, Error)` when upstream can fail.
- Use `@external(erlang, "atomvm_gleam_<module>_ffi", "<fun>")` for FFI.
- Prefer small Gleam wrappers that unpack config records, then call FFI.
- Document each public fn with a short `///` blurb and upstream link.
- Match existing constructor casing (`PinHigh`/`PinLow`, `EspRstSw`, …).

## FFI style

Mirror existing modules (`gpio_ffi`, `esp_ffi`, `network_ffi`, `ledc_ffi`):

- Map success `ok` → `{ok, nil}` (Gleam `Ok(Nil)`).
- Map bare `error` → `{error, failed}`.
- Map `{error, Reason}` through `wrap_reason/1`.
- Known atoms (`not_supported`, `badarg`, `timeout`, …) stay as Gleam zero-arity variants.
- Unknown atoms → `{error, {other, <<"...">>}}`.
- Integer LEDC-style codes → `{error, {code, N}}` when that pattern already exists.
- `Option(a)` ↔ `none` / `{some, Value}`.
- Remap Gleam constructors that would clash with Erlang atoms in FFI (example: `pin_high` → `high`).
- Convert Gleam `String` namespace/key args to atoms with `binary_to_atom(Name, utf8)` when upstream wants atoms.
- Catch `error:badarg` / `error:Reason` where NIFs can throw (see `esp_ffi`).
- `error:undef` → `NotSupported` only for **platform-gated** modules (`gpio`,
  `esp`, `pico`, `emscripten`, …). Universal modules (`crypto`, `console`, …)
  must not map `undef` to `NotSupported` (that hides missing beams / pack bugs).
- Upstream NIF stubs raise `undefined` (`erlang:nif_error(undefined)`). Map that
  to `Failed` / `Undefined` / `Other("undefined")`, never `NotSupported`,
  even on the platform that owns the module.

## Scope rules

- Touch **only** the files listed in the issue.
- Do not refactor unrelated modules, rename exports, or “clean up” style elsewhere.
- Do not wrap AtomVM 0.6-only APIs or revive removed modules (`network_fsm`, old `json_encoder`).
- Do not add dependencies unless the issue explicitly requires it.
- Keep PRs small and focused on the issue checklist.

## Verification

```sh
gleam format
gleam build
gleam test
```

When changing FFI modules, also pack and run the AtomVM harness on at least one
runtime that exercises the change:

```sh
./scripts/run_avm_unix.sh
# or: run_avm_wasm.sh / run_avm_esp32_qemu.sh / run_avm_pico_rp2040js.sh
```

Runners re-pack themselves. ESP32 and Pico use `pack_avm_tests.sh --no-libs` so
a host-built `atomvmlib` cannot shadow firmware `gpio` / platform modules.

Pico rp2040js uses a locally built non-W UF2 (`fetch_atomvm.sh pico`), not the
release Pico-W image (that hangs under the emulator).

Hardware flashing is optional unless the issue asks for it. Format, build, and
host tests must pass.

## Parallelism

Issues are split so agents do not edit the same files. If you need a shared helper, keep it private inside your module/FFI pair instead of changing another module.
