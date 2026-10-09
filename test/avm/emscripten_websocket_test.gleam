//// Browser websocket NIF smoke (WASM). Node AtomVM has no XHR — opening
//// a socket aborts the process, so we only hard-cover is_supported here.

import atomvm_gleam/emscripten_websocket as ews
import avm/check.{type Failure}
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  let _supported = ews.is_supported()
  use _ <- result.try(check.cover(
    "emscripten_websocket.is_supported",
    check.ok(),
  ))
  // Do not call new*/send*/close*: emscripten fetch uses XMLHttpRequest and
  // crashes node. Tag remaining APIs as off-platform for this harness.
  use _ <- result.try(check.cover_not_supported("emscripten_websocket.new"))
  use _ <- result.try(check.cover_not_supported("emscripten_websocket.new2"))
  use _ <- result.try(check.cover_not_supported("emscripten_websocket.new3"))
  use _ <- result.try(check.cover_not_supported(
    "emscripten_websocket.controlling_process",
  ))
  use _ <- result.try(check.cover_not_supported(
    "emscripten_websocket.ready_state",
  ))
  use _ <- result.try(check.cover_not_supported(
    "emscripten_websocket.buffered_amount",
  ))
  use _ <- result.try(check.cover_not_supported("emscripten_websocket.url"))
  use _ <- result.try(check.cover_not_supported(
    "emscripten_websocket.extensions",
  ))
  use _ <- result.try(check.cover_not_supported("emscripten_websocket.protocol"))
  use _ <- result.try(check.cover_not_supported(
    "emscripten_websocket.send_utf8",
  ))
  use _ <- result.try(check.cover_not_supported(
    "emscripten_websocket.send_binary",
  ))
  use _ <- result.try(check.cover_not_supported("emscripten_websocket.close"))
  use _ <- result.try(check.cover_not_supported("emscripten_websocket.close2"))
  use _ <- result.try(check.cover_not_supported("emscripten_websocket.close3"))
  Ok(Nil)
}
