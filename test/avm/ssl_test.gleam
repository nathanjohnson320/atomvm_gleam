//// SSL connect smoke on ESP32 and GenericUnix (mbedtls). `connect` must not
//// return NotSupported; connection refused / handshake failure counts as
//// exercising the FFI. send/recv/close only when connect returns a socket.

import atomvm_gleam/atomvm
import atomvm_gleam/ssl
import avm/check.{type Failure}
import avm/expect
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Esp32 | atomvm.GenericUnix -> ssl_socket_apis()
    _ -> check.ok()
  }
}

fn ssl_ns(e: ssl.Error) -> Bool {
  case e {
    ssl.NotSupported -> True
    ssl.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
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
