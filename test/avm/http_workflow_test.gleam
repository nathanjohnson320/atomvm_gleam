//// HTTP client + server integration on loopback (GenericUnix).
////
//// Exercises start_server → request → reply / reply_with_headers → stream
//// → close. Soft NotSupported tags are not used here: failure means the
//// workflow broke.
////
//// Prefer active-mode `stream` over passive `recv`: AtomVM `http_server:reply/3`
//// closes the socket after send, and passive `recv` can surface `{error, closed}`
//// before the body is read. Active mode reports a clean peer close as
//// `Closed` after a complete response.

import atomvm_gleam/http
import atomvm_gleam/http_server
import avm/check.{type Failure, Failure}
import avm/integration
import gleam/bit_array
import gleam/erlang/atom
import gleam/option
import gleam/result

const listen_port = 18_765

fn fail(message: String) -> Result(a, Failure) {
  Error(Failure(message))
}

pub fn run() -> Result(Nil, Failure) {
  use _ <- result.try(start_server())
  use _ <- result.try(get_root_roundtrip())
  use _ <- result.try(headers_roundtrip())
  use _ <- result.try(reply3_roundtrip())
  use _ <- result.try(passive_recv_roundtrip())
  Ok(Nil)
}

fn handler_routes() -> List(http_server.Route) {
  let mod = atom.create("avm_http_test_handler")
  [
    http_server.route("/", mod),
    http_server.route("/headers", mod),
    http_server.route("/reply3", mod),
    http_server.route("*", mod),
  ]
}

fn start_server() -> Result(Nil, Failure) {
  use _pid <- result.try(check.cover_ok(
    "http_server.start_server",
    http_server.start_server(listen_port, handler_routes()),
  ))
  integration.sleep_ms(50)
  Ok(Nil)
}

fn get_root_roundtrip() -> Result(Nil, Failure) {
  use #(status, body) <- result.try(active_get("/"))
  use _ <- result.try(check.assert_eq("root status", status, 200))
  use _ <- result.try(check.assert_eq("root body", body, <<"hello-gleam">>))
  // reply_with_headers (Gleam FFI reply/4) is used for the 200 paths.
  use _ <- result.try(check.cover("http_server.reply_with_headers", check.ok()))
  Ok(Nil)
}

fn headers_roundtrip() -> Result(Nil, Failure) {
  use #(status, body) <- result.try(active_get("/headers"))
  use _ <- result.try(check.assert_eq("headers status", status, 200))
  use _ <- result.try(check.assert_eq("headers body", body, <<"with-headers">>))
  Ok(Nil)
}

fn reply3_roundtrip() -> Result(Nil, Failure) {
  use #(status, body) <- result.try(active_get("/reply3"))
  use _ <- result.try(check.assert_eq("reply3 status", status, 200))
  use _ <- result.try(check.assert_eq("reply3 body", body, <<"via-reply3">>))
  use _ <- result.try(check.cover("http_server.reply", check.ok()))
  Ok(Nil)
}

/// Passive recv against reply/4 + Content-Length (socket still closed after
/// send by the handler). Asserts recv can parse a complete response when the
/// body length is known; may still see `closed` after Done on a follow-up.
fn passive_recv_roundtrip() -> Result(Nil, Failure) {
  use conn <- result.try(check.cover_ok(
    "http.connect",
    http.connect(http.Http, "127.0.0.1", listen_port, False, option.None),
  ))
  use #(conn, _ref) <- result.try(check.cover_ok(
    "http.request",
    http.request(conn, "GET", "/", [], http.Empty),
  ))
  use #(conn, status, body) <- result.try(recv_until_done_or_closed(
    conn,
    option.None,
    <<>>,
    8,
  ))
  use _ <- result.try(check.assert_eq("passive status", status, 200))
  use _ <- result.try(check.assert_eq("passive body", body, <<"hello-gleam">>))
  use _ <- result.try(check.cover_ok("http.close", http.close(conn)))
  Ok(Nil)
}

fn active_get(path: String) -> Result(#(Int, BitArray), Failure) {
  use conn <- result.try(check.cover_ok(
    "http.connect",
    http.connect(http.Http, "127.0.0.1", listen_port, True, option.None),
  ))
  use #(conn, _ref) <- result.try(check.cover_ok(
    "http.request",
    http.request(conn, "GET", path, [], http.Empty),
  ))
  use #(conn, status, body) <- result.try(stream_until_done(
    conn,
    option.None,
    <<>>,
    40,
  ))
  use _ <- result.try(check.cover_ok("http.close", http.close(conn)))
  Ok(#(status, body))
}

fn recv_until_done_or_closed(
  conn: http.Connection,
  status: option.Option(Int),
  body: BitArray,
  remaining: Int,
) -> Result(#(http.Connection, Int, BitArray), Failure) {
  case remaining <= 0 {
    True -> fail("http.recv: timeout waiting for Done")
    False -> {
      case http.recv(conn, 0) {
        Ok(#(conn2, responses)) -> {
          use _ <- result.try(check.cover("http.recv", check.ok()))
          let #(status2, body2, done) =
            fold_responses(responses, status, body, False)
          case done {
            True ->
              case status2 {
                option.Some(code) -> Ok(#(conn2, code, body2))
                option.None -> fail("http.recv: Done without Status")
              }
            False ->
              recv_until_done_or_closed(conn2, status2, body2, remaining - 1)
          }
        }
        Error(http.Other("closed")) ->
          case status {
            option.Some(code) -> {
              use _ <- result.try(check.cover("http.recv", check.ok()))
              Ok(#(conn, code, body))
            }
            option.None -> fail("http.recv: closed before Status")
          }
        Error(reason) -> fail("http.recv: " <> http.error_to_string(reason))
      }
    }
  }
}

fn stream_until_done(
  conn: http.Connection,
  status: option.Option(Int),
  body: BitArray,
  remaining: Int,
) -> Result(#(http.Connection, Int, BitArray), Failure) {
  case remaining <= 0 {
    True -> fail("http.stream: timeout waiting for Done")
    False -> {
      case integration.receive_any(500) {
        Error(Nil) -> fail("http.stream: no mailbox message")
        Ok(msg) -> {
          use event <- result.try(check.cover_ok(
            "http.stream",
            http.stream(conn, msg),
          ))
          case event {
            http.Unknown -> stream_until_done(conn, status, body, remaining - 1)
            http.Closed(conn2) ->
              case status {
                option.Some(code) -> Ok(#(conn2, code, body))
                option.None -> fail("http.stream: Closed without Status")
              }
            http.Responses(conn2, responses) -> {
              let #(status2, body2, done) =
                fold_responses(responses, status, body, False)
              case done {
                True ->
                  case status2 {
                    option.Some(code) -> Ok(#(conn2, code, body2))
                    option.None -> fail("http.stream: Done without Status")
                  }
                False -> stream_until_done(conn2, status2, body2, remaining - 1)
              }
            }
          }
        }
      }
    }
  }
}

fn fold_responses(
  responses: List(http.Response),
  status: option.Option(Int),
  body: BitArray,
  done: Bool,
) -> #(option.Option(Int), BitArray, Bool) {
  case responses {
    [] -> #(status, body, done)
    [http.Status(_ref, code), ..rest] ->
      fold_responses(rest, option.Some(code), body, done)
    [http.Data(_ref, chunk), ..rest] ->
      fold_responses(rest, status, bit_array.append(body, chunk), done)
    [http.Done(_ref), ..rest] -> fold_responses(rest, status, body, True)
    [http.Header(_, _, _), ..rest]
    | [http.HeaderContinuation(_, _, _), ..rest]
    | [http.TrailerHeader(_, _, _), ..rest] ->
      fold_responses(rest, status, body, done)
  }
}
