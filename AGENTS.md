# Agent instructions for atomvm_gleam

Typed Gleam wrappers for AtomVM **0.7** (`release-0.7` / `v0.7.0-beta.x`), not 0.6.

Upstream layout changed in 0.7: platform APIs live under `libs/avm_esp32`, `libs/avm_rp2`, `libs/avm_network`, etc. Prefer those sources and `doc.atomvm.org/release-0.7` over old monolithic `eavmlib` docs.

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
```

Hardware flashing is optional unless the issue asks for it. Compile/format must pass.

## Parallelism

Issues are split so agents do not edit the same files. If you need a shared helper, keep it private inside your module/FFI pair instead of changing another module.
