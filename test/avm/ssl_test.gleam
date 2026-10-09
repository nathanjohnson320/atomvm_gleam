//// SSL socket connect smoke (ESP32).

import atomvm_gleam/atomvm
import atomvm_gleam/ssl
import avm/check.{type Failure}
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Esp32 -> ssl_socket_apis()
    _ -> check.ok()
  }
}

fn ssl_socket_apis() -> Result(Nil, Failure) {
  case ssl.connect("127.0.0.1", 443, ssl.default_options()) {
    Ok(_) | Error(_) -> {
      use _ <- result.try(check.cover("ssl.connect", check.ok()))
      use _ <- result.try(check.cover_not_supported("ssl.send"))
      use _ <- result.try(check.cover_not_supported("ssl.recv"))
      use _ <- result.try(check.cover_not_supported("ssl.close"))
      Ok(Nil)
    }
  }
}
