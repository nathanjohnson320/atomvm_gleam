//// HTTP server parse helpers; live start/reply covered by http_workflow_test.

import atomvm_gleam/atomvm
import atomvm_gleam/http_server
import avm/check.{type Failure}
import avm/expect
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    _ -> http_server_parse()
  }
}

fn http_server_parse() -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_not_supported(
    "http_server.parse_query_string",
    http_server.parse_query_string("a=1"),
    fn(e) {
      case e {
        http_server.NotSupported -> True
        _ -> False
      }
    },
    http_server.error_to_string,
  ))
  // Live start_server / reply / reply_with_headers are hard-covered by
  // http_workflow_test on GenericUnix. Soft-tag elsewhere so we do not
  // demand a TCP peer on ESP32 QEMU / Pico / WASM.
  case atomvm.platform() {
    atomvm.GenericUnix -> Ok(Nil)
    _ -> {
      use _ <- result.try(check.cover_not_supported("http_server.start_server"))
      use _ <- result.try(check.cover_not_supported("http_server.reply"))
      use _ <- result.try(check.cover_not_supported(
        "http_server.reply_with_headers",
      ))
      Ok(Nil)
    }
  }
}
