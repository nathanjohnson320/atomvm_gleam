//// Browser websocket NIF smoke (WASM). Node AtomVM has no XHR - opening
//// a socket aborts the process, so we only hard-cover `is_supported` here.
//// Remaining APIs are intentionally untested in this harness (honest skip),
//// not fake-tagged as NotSupported.

import atomvm_gleam/emscripten_websocket as ews
import avm/check.{type Failure}
import avm/integration
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  let _supported = ews.is_supported()
  use _ <- result.try(check.cover(
    "emscripten_websocket.is_supported",
    check.ok(),
  ))
  integration.skip(
    "emscripten_websocket new/send/close (Node AtomVM aborts on XHR)",
  )
}
