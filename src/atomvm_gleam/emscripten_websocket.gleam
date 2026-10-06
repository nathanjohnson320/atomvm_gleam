//// Browser WebSocket NIF wrappers for AtomVM's emscripten-only `websocket`
//// module (`avm_emscripten`).
////
//// **Emscripten / browser only.** This is distinct from
//// [`atomvm_gleam/websocket`](atomvm_gleam/websocket.html), which wraps the
//// ESP-IDF `atomvm_websocket_client` port driver.
////
//// Naming: upstream Erlang exports the module as `websocket`, but that Gleam
//// path is already taken by the ESP client. This Gleam module is therefore
//// `emscripten_websocket`; the FFI still calls Erlang `websocket`.
////
//// Source:
//// [`libs/avm_emscripten/src/websocket.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_emscripten/src/websocket.erl).
//// Docs:
//// [Module websocket](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html).
////
//// ## Inbound owner messages
////
//// The controlling process receives these mailbox messages (from the NIF):
////
//// - `{websocket_open, Websocket}` — connection opened
//// - `{websocket, Websocket, Data}` — text or binary payload (`Data` is a binary)
//// - `{websocket_error, Websocket}` — error event
//// - `{websocket_close, Websocket, {WasClean, Code, Reason}}` — closed;
////   `WasClean` is a boolean, `Code` an integer status, `Reason` a binary
////
//// Check `atomvm.platform() == Emscripten` (or call [`is_supported`](#is_supported))
//// before using this module on mixed-target builds.

import gleam/erlang/process.{type Pid}

/// Opaque browser WebSocket resource (`websocket()`).
pub type Websocket

/// Connection ready-state from [`ready_state`](#ready_state).
pub type ReadyState {
  Connecting
  Open
  Closing
  Closed
}

/// Errors from the emscripten `websocket` NIF.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  /// Caller is not the current controlling process.
  NotOwner
  /// Socket is already closed (`{error, closed}` upstream).
  /// Named `SocketClosed` so it does not clash with [`ReadyState`](#ReadyState)'s `Closed`.
  SocketClosed
  Other(String)
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    NotOwner -> "not_owner"
    SocketClosed -> "closed"
    Other(reason) -> reason
  }
}

/// `true` if browser WebSockets are available in this environment.
///
/// See [`websocket:is_supported/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#is_supported-0).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "is_supported")
pub fn is_supported() -> Bool

/// Open a WebSocket to `url` with default protocols and `self()` as owner.
///
/// Equivalent to [`new3`](#new3) with `[]` protocols and the calling process.
///
/// See [`websocket:new/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#new-1).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "new_1")
pub fn new(url: String) -> Result(Websocket, Error)

/// Open a WebSocket to `url` negotiating `protocols`, with `self()` as owner.
///
/// See [`websocket:new/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#new-2).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "new_2")
pub fn new2(url: String, protocols: List(String)) -> Result(Websocket, Error)

/// Open a WebSocket to `url` with `protocols` and explicit `owner` process.
///
/// See [`websocket:new/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#new-3).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "new_3")
pub fn new3(
  url: String,
  protocols: List(String),
  owner: Pid,
) -> Result(Websocket, Error)

/// Transfer ownership to `owner`. Must be called by the current owner.
///
/// See [`websocket:controlling_process/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#controlling_process-2).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "controlling_process")
pub fn controlling_process(ws: Websocket, owner: Pid) -> Result(Nil, Error)

/// Current connection ready-state.
///
/// See [`websocket:ready_state/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#ready_state-1).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "ready_state")
pub fn ready_state(ws: Websocket) -> Result(ReadyState, Error)

/// Bytes queued with send but not yet transmitted.
///
/// See [`websocket:buffered_amount/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#buffered_amount-1).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "buffered_amount")
pub fn buffered_amount(ws: Websocket) -> Result(Int, Error)

/// URL used to open the socket.
///
/// See [`websocket:url/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#url-1).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "url")
pub fn url(ws: Websocket) -> Result(String, Error)

/// Extensions selected by the server, if any.
///
/// See [`websocket:extensions/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#extensions-1).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "extensions")
pub fn extensions(ws: Websocket) -> Result(String, Error)

/// Subprotocol selected by the server, if any.
///
/// See [`websocket:protocol/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#protocol-1).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "protocol")
pub fn protocol(ws: Websocket) -> Result(String, Error)

/// Send a UTF-8 text frame.
///
/// See [`websocket:send_utf8/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#send_utf8-2).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "send_utf8")
pub fn send_utf8(ws: Websocket, text: String) -> Result(Nil, Error)

/// Send a binary frame.
///
/// See [`websocket:send_binary/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#send_binary-2).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "send_binary")
pub fn send_binary(ws: Websocket, data: BitArray) -> Result(Nil, Error)

/// Close with status code 1000 (normal) and an empty reason.
///
/// See [`websocket:close/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#close-1).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "close_1")
pub fn close(ws: Websocket) -> Result(Nil, Error)

/// Close with the given status code and an empty reason.
///
/// See [`websocket:close/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#close-2).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "close_2")
pub fn close2(ws: Websocket, status_code: Int) -> Result(Nil, Error)

/// Close with status code and reason string.
///
/// See [`websocket:close/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/websocket.html#close-3).
@external(erlang, "atomvm_gleam_emscripten_websocket_ffi", "close_3")
pub fn close3(
  ws: Websocket,
  status_code: Int,
  reason: String,
) -> Result(Nil, Error)
