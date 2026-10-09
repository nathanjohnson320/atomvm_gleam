/// Thin Gleam wrappers for AtomVM `http_server` (0.7).
///
/// Source / docs: [`http_server.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/http_server.erl).
/// There is no release-0.7 Sphinx/edoc page; prefer GitHub over `/latest/.../eavmlib`.
///
/// ## Router callback expectations
///
/// Upstream `start_server/2` takes a **route table**, not a Gleam callback.
/// Each entry is `{Path, Module, Opts}` where:
///
/// - `Path` is an Erlang string (charlist), e.g. `"/"`, `"/api"`, or `"*"` (catch-all)
/// - `Module` is an atom naming an Erlang module that exports `handle_req/3`
/// - `Opts` is ignored by AtomVM today (this wrapper always passes `[]`)
///
/// When a request matches, AtomVM calls:
///
/// ```text
/// Module:handle_req(Method, PathTokens, Conn) -> {ok, UpdatedConn}
/// ```
///
/// with Erlang terms:
///
/// - `Method` - charlist, e.g. `"GET"`
/// - `PathTokens` - list of path segments (charlists) after splitting on `/`
/// - `Conn` - proplist (`method`, `uri`, `http_version`, `header`, `body_chunk`, `socket`, …)
///
/// Handlers typically finish with [`reply`](#reply) / [`reply_with_headers`](#reply_with_headers).
///
/// ### Gleam interop
///
/// Pass [`Route`](#Route) values built with [`route`](#route). The `module` field must
/// be an Erlang module atom (`gleam/erlang/atom.create("my_handler")`) whose
/// `handle_req/3` matches the upstream signature. Writing that callback in pure
/// Gleam is awkward (charlists / proplists); the practical pattern used in AtomVM
/// examples is a small Erlang handler module that calls back into Gleam if needed.
import gleam/erlang/atom.{type Atom}
import gleam/erlang/process.{type Pid}

/// Opaque connection proplist from `http_server` (`[{socket, …}, {method, …}, …]`).
pub type Conn

/// Errors from `http_server` / TCP listen.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// One router entry: path pattern + Erlang handler module atom.
///
/// Path `"*"` matches any URI (last-resort / catch-all), matching upstream
/// `find_route/3`. Exact path strings must match the request URI charlist.
pub type Route {
  Route(path: String, module: Atom)
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

/// Build a router entry for [`start_server`](#start_server).
pub fn route(path: String, module: Atom) -> Route {
  Route(path:, module:)
}

/// Listen on `port` and accept connections, dispatching via `routes`.
///
/// Returns the accept-loop pid. On listen failure upstream prints the error and
/// this wrapper maps a non-pid result to [`Failed`](#Error).
///
/// See [`http_server:start_server/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/http_server.erl).
pub fn start_server(port: Int, routes: List(Route)) -> Result(Pid, Error) {
  start_server_ffi(port, routes)
}

/// Reply with status and body, default HTML headers, then close the socket.
///
/// See [`http_server:reply/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/http_server.erl).
@external(erlang, "atomvm_gleam_http_server_ffi", "reply")
pub fn reply(
  status_code: Int,
  body: BitArray,
  conn: Conn,
) -> Result(Conn, Error)

/// Reply with status, body, and custom header lines (each including trailing `\r\n`).
///
/// Does not close the socket by itself (unlike [`reply`](#reply)).
///
/// See [`http_server:reply/4`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/http_server.erl).
@external(erlang, "atomvm_gleam_http_server_ffi", "reply")
pub fn reply_with_headers(
  status_code: Int,
  body: BitArray,
  headers: List(BitArray),
  conn: Conn,
) -> Result(Conn, Error)

/// Parse an `application/x-www-form-urlencoded` query string into key/value pairs.
///
/// See [`http_server:parse_query_string/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/http_server.erl).
@external(erlang, "atomvm_gleam_http_server_ffi", "parse_query_string")
pub fn parse_query_string(
  query: String,
) -> Result(List(#(String, String)), Error)

@external(erlang, "atomvm_gleam_http_server_ffi", "start_server")
fn start_server_ffi(port: Int, routes: List(Route)) -> Result(Pid, Error)
