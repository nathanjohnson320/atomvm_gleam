//// HTTP client connect smoke. Full request/stream/recv path is
//// `http_workflow_test` (GenericUnix). Here we only prove `connect` is
//// available on platforms that own TCP/HTTP — never tag uncalled APIs.

import atomvm_gleam/atomvm
import atomvm_gleam/http
import avm/check.{type Failure}
import avm/expect
import gleam/option
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  // Node WASM / Pico: incomplete TCP stacks can abort instead of returning.
  case atomvm.platform() {
    atomvm.Emscripten | atomvm.Pico -> check.ok()
    atomvm.GenericUnix | atomvm.Esp32 -> http_connect_owned()
    atomvm.Stm32 -> http_connect_owned()
  }
}

fn http_ns(e: http.Error) -> Bool {
  case e {
    http.NotSupported -> True
    http.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
  }
}

fn http_connect_owned() -> Result(Nil, Failure) {
  // Port 9 (discard) — connect may Ok or fail with a runtime network error;
  // NotSupported means the module is missing on an owning platform → fail.
  case http.connect(http.Http, "127.0.0.1", 9, False, option.None) {
    Ok(conn) -> {
      use _ <- result.try(check.cover("http.connect", check.ok()))
      expect.must_ok("http.close", http.close(conn), http.error_to_string)
    }
    Error(reason) ->
      case http_ns(reason) {
        True ->
          check.fail(
            "http.connect: NotSupported on owning platform ("
            <> http.error_to_string(reason)
            <> ")",
          )
        False -> check.cover("http.connect", check.ok())
      }
  }
}
