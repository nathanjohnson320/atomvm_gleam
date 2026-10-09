//// SSL connect smoke where mbedtls is expected (unix, ESP32, Pico, STM32).
//// `connect` must not return NotSupported; connection refused / handshake
//// failure counts as exercising the FFI. send/recv/close only when a socket
//// opens. Pico under rp2040js: TCP can abort the VM — SKIP unless INTEGRATION
//// (same harness limit as http_test). WASM: no-op.

import atomvm_gleam/atomvm
import atomvm_gleam/ssl
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    atomvm.Esp32 | atomvm.GenericUnix | atomvm.Stm32 -> ssl_socket_apis()
    atomvm.Pico -> ssl_pico()
  }
}

fn ssl_ns(e: ssl.Error) -> Bool {
  case e {
    ssl.NotSupported -> True
    ssl.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
  }
}

fn ssl_pico() -> Result(Nil, Failure) {
  case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False ->
      integration.skip(
        "ssl.connect (rp2040js TCP abort risk; set AVM_GLEAM_INTEGRATION=1 on hardware)",
      )
    True -> ssl_socket_apis()
  }
}

fn ssl_socket_apis() -> Result(Nil, Failure) {
  case ssl.connect("127.0.0.1", 443, ssl.default_options()) {
    Ok(sock) -> {
      use _ <- result.try(check.cover("ssl.connect", check.ok()))
      use _ <- result.try(expect.ok_or_runtime(
        "ssl.send",
        ssl.send(sock, <<"x">>),
        fn(e) {
          case e {
            ssl.NotSupported -> False
            _ -> True
          }
        },
        ssl.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_runtime(
        "ssl.recv",
        ssl.recv(sock, 0),
        fn(e) {
          case e {
            ssl.NotSupported -> False
            _ -> True
          }
        },
        ssl.error_to_string,
      ))
      expect.must_ok("ssl.close", ssl.close(sock), ssl.error_to_string)
    }
    Error(reason) ->
      case ssl_ns(reason) {
        True ->
          check.fail(
            "ssl.connect: NotSupported on owning platform ("
            <> ssl.error_to_string(reason)
            <> ")",
          )
        False -> check.cover("ssl.connect", check.ok())
      }
  }
}
