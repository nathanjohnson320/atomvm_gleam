/// HTTP(S) client wrappers around AtomVM `ahttp_client`.
///
/// Source: [`ahttp_client.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/ahttp_client.erl).
/// Edoc fallback: [Module ahttp_client](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ahttp_client.html).
///
/// Call [`atomvm_gleam/ssl.start`](atomvm_gleam/ssl.html#start) before HTTPS.
import gleam/option.{type Option}

/// Opaque HTTP connection handle.
pub type Connection

/// Opaque request reference from [`request`](#request).
pub type Ref

/// Errors from `ahttp_client`.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// `http` or `https`.
pub type Protocol {
  Http
  Https
}

/// TLS / socket verify mode passed through to `ssl` options.
pub type Verify {
  VerifyNone
  VerifyPeer
}

/// One parsed response element from [`recv`](#recv).
pub type Response {
  Status(ref: Ref, code: Int)
  Header(ref: Ref, name: BitArray, value: BitArray)
  HeaderContinuation(ref: Ref, name: BitArray, value: BitArray)
  Data(ref: Ref, body: BitArray)
  Done(ref: Ref)
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    Other(reason) -> reason
  }
}

/// Connect to an HTTP(S) server.
///
/// See [`ahttp_client:connect/4`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ahttp_client.html#connect-4).
@external(erlang, "atomvm_gleam_http_ffi", "connect")
pub fn connect(
  protocol: Protocol,
  host: String,
  port: Int,
  active: Bool,
  verify: Option(Verify),
) -> Result(Connection, Error)

/// Send an HTTP request. Pass `None` for no body.
///
/// See [`ahttp_client:request/5`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ahttp_client.html#request-5).
@external(erlang, "atomvm_gleam_http_ffi", "request")
pub fn request(
  conn: Connection,
  method: String,
  path: String,
  headers: List(#(String, String)),
  body: Option(BitArray),
) -> Result(#(Connection, Ref), Error)

/// Receive and parse up to `len` bytes (`0` = all pending).
///
/// See [`ahttp_client:recv/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ahttp_client.html#recv-2).
@external(erlang, "atomvm_gleam_http_ffi", "recv")
pub fn recv(
  conn: Connection,
  len: Int,
) -> Result(#(Connection, List(Response)), Error)

/// Close the connection.
///
/// See [`ahttp_client:close/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ahttp_client.html#close-1).
@external(erlang, "atomvm_gleam_http_ffi", "close")
pub fn close(conn: Connection) -> Result(Nil, Error)
