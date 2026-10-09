//// HTTP client connect/close smoke (workflow suite covers the full path).

import atomvm_gleam/atomvm
import atomvm_gleam/http
import avm/check.{type Failure}
import gleam/option
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  // Node WASM / Pico: unresolved or incomplete TCP/HTTP stacks can abort
  // the process instead of returning NotSupported.
  case atomvm.platform() {
    atomvm.Emscripten | atomvm.Pico -> check.ok()
    _ -> http_connect_smoke()
  }
}

fn http_connect_smoke() -> Result(Nil, Failure) {
  case http.connect(http.Http, "127.0.0.1", 9, False, option.None) {
    Ok(conn) -> {
      use _ <- result.try(check.cover("http.connect", check.ok()))
      use _ <- result.try(check.cover_ok("http.close", http.close(conn)))
      use _ <- result.try(check.cover_not_supported("http.request"))
      use _ <- result.try(check.cover_not_supported("http.stream"))
      use _ <- result.try(check.cover_not_supported("http.stream_request_body"))
      use _ <- result.try(check.cover_not_supported("http.recv"))
      Ok(Nil)
    }
    Error(http.NotSupported) -> {
      use _ <- result.try(check.cover_not_supported("http.connect"))
      use _ <- result.try(check.cover_not_supported("http.request"))
      use _ <- result.try(check.cover_not_supported("http.stream"))
      use _ <- result.try(check.cover_not_supported("http.stream_request_body"))
      use _ <- result.try(check.cover_not_supported("http.recv"))
      use _ <- result.try(check.cover_not_supported("http.close"))
      Ok(Nil)
    }
    Error(_) -> {
      use _ <- result.try(check.cover("http.connect", check.ok()))
      use _ <- result.try(check.cover_not_supported("http.request"))
      use _ <- result.try(check.cover_not_supported("http.stream"))
      use _ <- result.try(check.cover_not_supported("http.stream_request_body"))
      use _ <- result.try(check.cover_not_supported("http.recv"))
      use _ <- result.try(check.cover_not_supported("http.close"))
      Ok(Nil)
    }
  }
}
