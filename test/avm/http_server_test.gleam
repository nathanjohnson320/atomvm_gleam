//// HTTP server parse helpers. Live start/reply is `http_workflow_test`
//// (GenericUnix only). Parse APIs are pure Erlang in atomvmlib - must Ok
//// wherever the module is packed (unix / ESP). Off / WASM: no-op or NotSupported.

import atomvm_gleam/atomvm
import atomvm_gleam/http_server
import avm/check.{type Failure}
import avm/expect

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    // Parse helpers ship in atomvmlib / firmware on unix + MCU targets.
    atomvm.GenericUnix | atomvm.Esp32 | atomvm.Pico | atomvm.Stm32 ->
      http_server_parse_owned()
  }
}

fn http_server_parse_owned() -> Result(Nil, Failure) {
  expect.must_ok(
    "http_server.parse_query_string",
    http_server.parse_query_string("a=1"),
    http_server.error_to_string,
  )
}
