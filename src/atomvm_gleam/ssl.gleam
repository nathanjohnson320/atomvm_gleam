/// Thin wrappers for AtomVM `:ssl` client sockets.
///
/// Source: [`ssl.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/estdlib/src/ssl.erl).
/// Docs: [Module ssl](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/ssl.html).
///
/// For HTTPS, prefer [`atomvm_gleam/http`](atomvm_gleam/http.html) after calling
/// [`start`](#start). Use this module for raw TLS sockets.
import gleam/option.{type Option}

/// Opaque SSL socket (`sslsocket()`).
pub type Socket

/// Errors from `:ssl`.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Closed
  Nxdomain
  Other(String)
}

/// TLS verify mode passed through to `ssl` options.
///
/// AtomVM 0.7 documents `{verify, verify_none}` as the supported client verify option.
pub type Verify {
  VerifyNone
}

/// `server_name_indication` client option.
pub type ServerNameIndication {
  Hostname(String)
  Disabled
}

/// Client options for [`connect`](#connect).
///
/// The FFI always adds `{active, false}` and `binary`, which AtomVM requires.
pub type Options {
  Options(
    verify: Option(Verify),
    server_name_indication: Option(ServerNameIndication),
  )
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    Closed -> "closed"
    Nxdomain -> "nxdomain"
    Other(reason) -> reason
  }
}

/// Empty options (driver / AtomVM defaults, plus required `{active, false}`).
pub fn default_options() -> Options {
  Options(verify: option.None, server_name_indication: option.None)
}

/// Start the SSL application.
///
/// See [`ssl:start/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/ssl.html#start-0).
@external(erlang, "atomvm_gleam_ssl_ffi", "start")
pub fn start() -> Nil

/// Stop the SSL application.
///
/// See [`ssl:stop/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/ssl.html#stop-0).
@external(erlang, "atomvm_gleam_ssl_ffi", "stop")
pub fn stop() -> Nil

/// Connect as a TLS client to `host`:`port`.
///
/// See [`ssl:connect/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/ssl.html#connect-3).
pub fn connect(
  host: String,
  port: Int,
  options: Options,
) -> Result(Socket, Error) {
  let Options(verify:, server_name_indication:) = options
  connect_ffi(host, port, verify, server_name_indication)
}

/// Send data on an SSL socket.
///
/// See [`ssl:send/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/ssl.html#send-2).
@external(erlang, "atomvm_gleam_ssl_ffi", "send")
pub fn send(socket: Socket, data: BitArray) -> Result(Nil, Error)

/// Receive up to `length` bytes (`0` = read available data).
///
/// See [`ssl:recv/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/ssl.html#recv-2).
@external(erlang, "atomvm_gleam_ssl_ffi", "recv")
pub fn recv(socket: Socket, length: Int) -> Result(BitArray, Error)

/// Close the SSL socket.
///
/// See [`ssl:close/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/ssl.html#close-1).
@external(erlang, "atomvm_gleam_ssl_ffi", "close")
pub fn close(socket: Socket) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_ssl_ffi", "connect")
fn connect_ffi(
  host: String,
  port: Int,
  verify: Option(Verify),
  server_name_indication: Option(ServerNameIndication),
) -> Result(Socket, Error)
