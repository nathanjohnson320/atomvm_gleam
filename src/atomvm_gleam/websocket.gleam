/// Gleam face for [`atomvm_websocket_client`](https://github.com/nerves-hub/atomvm_websocket_client).
///
/// Requires the ESP-IDF websocket port driver in the AtomVM base image.
/// Inbound messages to `owner`:
///
/// - `{websocket, Port, connected}`
/// - `{websocket, Port, {text, Binary}}`
/// - `{websocket, Port, {binary, Binary}}`
/// - `{websocket, Port, {closed, Reason}}`
/// - `{websocket, Port, {error, Reason}}`
import gleam/erlang/process.{type Pid}
import gleam/option.{type Option}

/// Opaque websocket port handle.
pub type Websocket

/// Errors from the websocket client.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  MissingUrl
  NotConnected
  Other(String)
}

/// TLS verification mode.
pub type Verify {
  /// ESP-IDF CA certificate bundle (typical for public `wss://` hosts).
  CrtBundle
  /// No verification (development / cleartext `ws://` only).
  NoVerify
}

/// Open options. `url` is required; other fields are optional.
pub type Config {
  Config(
    url: String,
    owner: Option(Pid),
    verify: Option(Verify),
    network_timeout_ms: Option(Int),
    disable_auto_reconnect: Option(Bool),
  )
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    MissingUrl -> "missing_url"
    NotConnected -> "not_connected"
    Other(reason) -> reason
  }
}

/// Open a websocket. Returns once the port exists — wait for `connected`
/// before sending.
pub fn open(config: Config) -> Result(Websocket, Error) {
  let Config(
    url:,
    owner:,
    verify:,
    network_timeout_ms:,
    disable_auto_reconnect:,
  ) = config
  open_ffi(url, owner, verify, network_timeout_ms, disable_auto_reconnect)
}

/// Send a text frame.
@external(erlang, "atomvm_gleam_websocket_ffi", "send_text")
pub fn send_text(ws: Websocket, data: BitArray) -> Result(Nil, Error)

/// Send a binary frame.
@external(erlang, "atomvm_gleam_websocket_ffi", "send_binary")
pub fn send_binary(ws: Websocket, data: BitArray) -> Result(Nil, Error)

/// Close the connection.
@external(erlang, "atomvm_gleam_websocket_ffi", "close")
pub fn close(ws: Websocket) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_websocket_ffi", "open")
fn open_ffi(
  url: String,
  owner: Option(Pid),
  verify: Option(Verify),
  network_timeout_ms: Option(Int),
  disable_auto_reconnect: Option(Bool),
) -> Result(Websocket, Error)
