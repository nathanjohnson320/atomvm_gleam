//// ESP websocket client. Without INTEGRATION: honest SKIP (no fake tags).
//// With INTEGRATION: `open` must not return NotSupported; send/close only
//// when a handle is returned.

import atomvm_gleam/atomvm
import atomvm_gleam/websocket
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/option
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Esp32 -> esp_websocket()
    _ -> check.ok()
  }
}

fn ws_ns(e: websocket.Error) -> Bool {
  case e {
    websocket.NotSupported -> True
    websocket.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
  }
}

fn esp_websocket() -> Result(Nil, Failure) {
  case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False ->
      integration.skip(
        "websocket.* (needs live peer; set AVM_GLEAM_INTEGRATION=1)",
      )
    True -> esp_websocket_live()
  }
}

fn esp_websocket_live() -> Result(Nil, Failure) {
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
      use _ <- result.try(expect.ok_or_runtime(
        "websocket.send_text",
        websocket.send_text(ws, <<"hi">>),
        fn(e) {
          case e {
            websocket.NotSupported -> False
            _ -> True
          }
        },
        websocket.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_runtime(
        "websocket.send_binary",
        websocket.send_binary(ws, <<"hi">>),
        fn(e) {
          case e {
            websocket.NotSupported -> False
            _ -> True
          }
        },
        websocket.error_to_string,
      ))
      expect.ok_or_runtime(
        "websocket.close",
        websocket.close(ws),
        fn(e) {
          case e {
            websocket.NotSupported -> False
            _ -> True
          }
        },
        websocket.error_to_string,
      )
    }
    Error(reason) ->
      case ws_ns(reason) {
        True ->
          check.fail(
            "websocket.open: NotSupported on ESP32 ("
            <> websocket.error_to_string(reason)
            <> ")",
          )
        False -> check.cover("websocket.open", check.ok())
      }
  }
}
