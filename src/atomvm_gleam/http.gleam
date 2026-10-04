/// HTTP(S) client wrappers around AtomVM `ahttp_client`.
///
/// Source: [`ahttp_client.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/ahttp_client.erl).
/// Edoc fallback: [Module ahttp_client](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ahttp_client.html).
///
/// Call [`atomvm_gleam/ssl.start`](atomvm_gleam/ssl.html#start) before HTTPS.
///
/// ## Active mode and chunked responses
///
/// Open with `active: True` (the usual default). After [`request`](#request),
/// feed each mailbox message into [`stream`](#stream) and keep the returned
/// connection for the next call:
///
/// 1. Expect [`Status`](#Response) first, then [`Header`](#Response) events.
/// 2. Body arrives as one or more [`Data`](#Response) chunks (sub-binaries of
///    the socket buffer — copy with `binary:copy/1` if you retain them).
/// 3. Chunked transfer encoding (0.7) ends with optional
///    [`TrailerHeader`](#Response) events, then [`Done`](#Response).
/// 4. [`Closed`](#StreamEvent) means the peer closed after a complete response;
///    [`Unknown`](#StreamEvent) means the message was not for this socket.
///
/// Passive mode (`active: False`) uses [`recv`](#recv) instead of `stream`.
///
/// For large uploads, pass [`Stream`](#Body) to [`request`](#request) (with an
/// explicit `Content-Length` header) and send chunks via
/// [`stream_request_body`](#stream_request_body).
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

/// Request body for [`request`](#request).
pub type Body {
  /// No body (`undefined` / `nil` upstream).
  Empty
  /// Inline body; `Content-Length` is set automatically.
  Bytes(BitArray)
  /// Streamed upload via [`stream_request_body`](#stream_request_body).
  /// Pair with an explicit `Content-Length` header.
  Stream
}

/// One parsed response element from [`recv`](#recv) / [`stream`](#stream).
pub type Response {
  Status(ref: Ref, code: Int)
  Header(ref: Ref, name: BitArray, value: BitArray)
  /// Deprecated: AtomVM 0.7 no longer emits obs-fold / header continuation.
  /// Kept for binary compatibility with older response lists.
  HeaderContinuation(ref: Ref, name: BitArray, value: BitArray)
  /// Trailer field after a chunked body (0.7).
  TrailerHeader(ref: Ref, name: BitArray, value: BitArray)
  Data(ref: Ref, body: BitArray)
  Done(ref: Ref)
}

/// Outcome of feeding one mailbox message into [`stream`](#stream).
pub type StreamEvent {
  /// Parsed HTTP response pieces for this message.
  Responses(Connection, List(Response))
  /// Peer closed after a complete response (or with no in-flight parse).
  Closed(Connection)
  /// Message was not a socket message for this connection.
  Unknown
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

/// Send an HTTP request.
///
/// Pass [`Empty`](#Body) for no body, [`Bytes`](#Body) for an inline payload, or
/// [`Stream`](#Body) to upload with [`stream_request_body`](#stream_request_body).
///
/// See [`ahttp_client:request/5`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ahttp_client.html#request-5).
@external(erlang, "atomvm_gleam_http_ffi", "request")
pub fn request(
  conn: Connection,
  method: String,
  path: String,
  headers: List(#(String, String)),
  body: Body,
) -> Result(#(Connection, Ref), Error)

/// Feed a socket mailbox message into the HTTP parser (active mode).
///
/// Returns updated connection + response events, [`Closed`](#StreamEvent) on a
/// clean peer close, or [`Unknown`](#StreamEvent) when `message` is unrelated.
/// Parser failures (line too long, incomplete response, invalid chunk size,
/// …) map to [`Error`](#Error) / [`Other`](#Error).
///
/// See [`ahttp_client:stream/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ahttp_client.html#stream-2).
@external(erlang, "atomvm_gleam_http_ffi", "stream")
pub fn stream(conn: Connection, message: message) -> Result(StreamEvent, Error)

/// Upload one chunk of a streamed request body.
///
/// Only valid after [`request`](#request) with [`Stream`](#Body). `ref` must be
/// the reference from that request.
///
/// See [`ahttp_client:stream_request_body/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ahttp_client.html#stream_request_body-3).
@external(erlang, "atomvm_gleam_http_ffi", "stream_request_body")
pub fn stream_request_body(
  conn: Connection,
  ref: Ref,
  chunk: BitArray,
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
