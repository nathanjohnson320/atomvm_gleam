//// Emscripten core (run_script / tracked). Event + websocket suites are separate.

import atomvm_gleam/emscripten
import avm/check.{type Failure}
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  use _ <- result.try(check.cover_ok(
    "emscripten.run_script",
    emscripten.run_script("1 + 1"),
  ))
  use _ <- result.try(check.cover_ok(
    "emscripten.run_script_with",
    emscripten.run_script_with("1 + 1", [emscripten.MainThread]),
  ))
  use tracked <- result.try(check.cover_ok(
    "emscripten.run_script_tracked",
    emscripten.run_script_tracked("[\"hello\"]"),
  ))
  use _ <- result.try(check.cover_ok(
    "emscripten.get_tracked",
    emscripten.get_tracked(tracked, emscripten.TrackedKey),
  ))
  // Promise APIs need a live Promise handle from JS; tag via NotSupported-style
  // absence is wrong on WASM. Call with a bogus handle only if API accepts —
  // skip destructive misuse; cover via negative off-platform instead.
  Ok(Nil)
}
