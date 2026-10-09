/// Topic pub/sub helper wrapping AtomVM's `avm_pubsub` gen_server (0.7).
///
/// Start a broker with [`start`](#start) / [`start_named`](#start_named),
/// subscribe with [`sub`](#sub) / [`sub_pid`](#sub_pid), publish with
/// [`publish`](#publish) (upstream `pub/3`), and unsubscribe with
/// [`unsub`](#unsub) / [`unsub_pid`](#unsub_pid).
///
/// ## Inbound subscriber messages
///
/// When a matching publish occurs, each subscriber receives an Erlang message:
///
/// ```text
/// {pub, Topic, From, Term}
/// ```
///
/// - `Topic` - the published topic term
/// - `From` - pid of the process that called [`publish`](#publish)
/// - `Term` - the published payload
///
/// Topics are Erlang terms upstream (often lists of atoms for MQTT-style
/// patterns with `'+'` / `'#'`). Prefer simple atoms, binaries, ints, or
/// lists of those when calling from Gleam.
///
/// Source: [`avm_pubsub.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/avm_pubsub.erl#L1).
/// Docs: [Module avm_pubsub](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/avm_pubsub.html).
import gleam/erlang/process.{type Pid}

/// Opaque handle for a running `avm_pubsub` gen_server (`pid()`).
pub type Server

/// Errors from `avm_pubsub` / `gen_server`.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
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

/// Start an unnamed `avm_pubsub` gen_server.
///
/// See [`avm_pubsub:start/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/avm_pubsub.erl#L26).
@external(erlang, "atomvm_gleam_avm_pubsub_ffi", "start")
pub fn start() -> Result(Server, Error)

/// Start an `avm_pubsub` gen_server registered under a local atom name.
///
/// `name` is converted to an atom in the FFI (`binary_to_atom/2`), matching
/// other modules that accept Gleam `String` names.
///
/// See [`avm_pubsub:start/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/avm_pubsub.erl#L29).
@external(erlang, "atomvm_gleam_avm_pubsub_ffi", "start_named")
pub fn start_named(name: String) -> Result(Server, Error)

/// Publish `term` on `topic`. Returns the number of matching subscribers notified.
///
/// Maps to upstream `avm_pubsub:pub/3` (`pub` is a Gleam keyword).
///
/// See [`avm_pubsub:pub/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/avm_pubsub.erl#L32).
@external(erlang, "atomvm_gleam_avm_pubsub_ffi", "publish")
pub fn publish(server: Server, topic: topic, term: term) -> Result(Int, Error)

/// Subscribe the calling process to `topic`.
///
/// See [`avm_pubsub:sub/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/avm_pubsub.erl#L35).
@external(erlang, "atomvm_gleam_avm_pubsub_ffi", "sub")
pub fn sub(server: Server, topic: topic) -> Result(Nil, Error)

/// Subscribe `pid` to `topic`.
///
/// See [`avm_pubsub:sub/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/avm_pubsub.erl#L38).
@external(erlang, "atomvm_gleam_avm_pubsub_ffi", "sub_pid")
pub fn sub_pid(server: Server, topic: topic, pid: Pid) -> Result(Nil, Error)

/// Unsubscribe the calling process from `topic`.
///
/// See [`avm_pubsub:unsub/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/avm_pubsub.erl#L41).
@external(erlang, "atomvm_gleam_avm_pubsub_ffi", "unsub")
pub fn unsub(server: Server, topic: topic) -> Result(Nil, Error)

/// Unsubscribe `pid` from `topic`.
///
/// See [`avm_pubsub:unsub/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/avm_pubsub.erl#L44).
@external(erlang, "atomvm_gleam_avm_pubsub_ffi", "unsub_pid")
pub fn unsub_pid(server: Server, topic: topic, pid: Pid) -> Result(Nil, Error)
