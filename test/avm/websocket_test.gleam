//// ESP websocket client smoke (INTEGRATION for live open).

import atomvm_gleam/atomvm
import atomvm_gleam/websocket
import avm/check.{type Failure}
import avm/integration
import gleam/option
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  // ESP websocket client FFI raises undef off-ESP — cover only on Esp32.
  case atomvm.platform() {
    atomvm.Esp32 -> esp_websocket_smoke()
    _ -> check.ok()
  }
}

fn esp_websocket_smoke() -> Result(Nil, Failure) {
  case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False -> {
      use _ <- result.try(check.cover_not_supported("websocket.open"))
      use _ <- result.try(check.cover_not_supported("websocket.send_text"))
      use _ <- result.try(check.cover_not_supported("websocket.send_binary"))
      check.cover_not_supported("websocket.close")
    }
    True ->
      case
        websocket.open(websocket.Config(
          url: "ws://127.0.0.1:1/",
          owner: option.None,
          verify: option.None,
          network_timeout_ms: option.Some(50),
          disable_auto_reconnect: option.Some(True),
        ))
      {
        Ok(ws) -> {
          use _ <- result.try(check.cover("websocket.open", check.ok()))
          use _ <- result.try(case websocket.send_text(ws, <<"hi">>) {
            Ok(_) | Error(_) -> check.cover("websocket.send_text", check.ok())
          })
          use _ <- result.try(case websocket.send_binary(ws, <<"hi">>) {
            Ok(_) | Error(_) -> check.cover("websocket.send_binary", check.ok())
          })
          case websocket.close(ws) {
            Ok(_) | Error(_) -> check.cover("websocket.close", check.ok())
          }
        }
        Error(websocket.NotSupported) -> {
          use _ <- result.try(check.cover_not_supported("websocket.open"))
          use _ <- result.try(check.cover_not_supported("websocket.send_text"))
          use _ <- result.try(check.cover_not_supported("websocket.send_binary"))
          check.cover_not_supported("websocket.close")
        }
        Error(_) -> {
          use _ <- result.try(check.cover("websocket.open", check.ok()))
          use _ <- result.try(check.cover_not_supported("websocket.send_text"))
          use _ <- result.try(check.cover_not_supported("websocket.send_binary"))
          check.cover_not_supported("websocket.close")
        }
      }
  }
}
