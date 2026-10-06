//// Typed Gleam wrappers for AtomVM emscripten JS interop (`emscripten` module).
////
//// **Emscripten / WASM platform only.** On other platforms NIFs are undefined
//// and calls return `NotSupported`.
////
//// JavaScript can send messages to a registered Erlang process:
////
//// - `Module.cast('proc', 'message')` → `{emscripten, {cast, <<"message">>}}`
//// - `await Module.call('proc', 'message')` →
////   `{emscripten, {call, Promise, <<"message">>}}`
////
//// Resolve or reject the opaque `Promise` with [`promise_resolve`](#promise_resolve)
//// / [`promise_reject`](#promise_reject). Tracked handles from
//// [`run_script_tracked`](#run_script_tracked) keep JS values alive until GC.
////
//// Upstream:
//// [`libs/avm_emscripten/src/emscripten.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_emscripten/src/emscripten.erl)
//// · Docs:
//// [Module emscripten](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html)

/// Opaque promise resource from `{emscripten, {call, Promise, Msg}}`.
///
/// Pass to [`promise_resolve`](#promise_resolve) or
/// [`promise_reject`](#promise_reject). Upstream type is an opaque binary.
pub type Promise

/// Opaque handle to a JavaScript value kept alive in `Module.trackedObjectsMap`
/// until this term is garbage-collected.
pub type TrackedObject

/// Errors from emscripten NIFs and helpers.
///
/// Known reason atoms are Gleam constructors (so `{error, not_supported}` is
/// `Error(NotSupported)`). Bare AtomVM `error` becomes `Failed`. Anything else
/// lands in `Other` as a string.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// Options for [`run_script_with`](#run_script_with). Map to Erlang
/// `main_thread` / `async`.
///
/// `Async` only applies when `MainThread` is also specified.
pub type RunScriptOption {
  MainThread
  Async
}

/// Field selector for [`get_tracked`](#get_tracked). FFI remaps to Erlang
/// `key` / `value` (Gleam atoms would be `tracked_key` / `tracked_value`).
pub type TrackedField {
  TrackedKey
  TrackedValue
}

/// Per-handle result when fetching tracked values (`TrackedValue`).
///
/// Upstream: `{ok, Binary}` | `{error, badkey}` | `{error, badvalue}`.
pub type TrackedFetchError {
  BadKey
  BadValue
}

/// Result of [`get_tracked`](#get_tracked): integer keys or per-handle values.
pub type GetTracked {
  Keys(List(Int))
  Values(List(Result(BitArray, TrackedFetchError)))
}

/// Value passed to [`promise_resolve_with`](#promise_resolve_with) /
/// [`promise_reject_with`](#promise_reject_with).
///
/// Upstream accepts an integer or iodata (string).
pub type PromiseValue {
  IntValue(Int)
  StringValue(String)
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

/// Run a script on the current worker thread (rarely useful alone).
///
/// Prefer [`run_script_with`](#run_script_with) with `[MainThread]` or
/// `[MainThread, Async]`. Exception handling is disabled — a throw or compile
/// error crashes the VM.
///
/// Gleam cannot overload by arity; this is Erlang `run_script/1`.
///
/// See [`emscripten:run_script/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#run_script-1).
@external(erlang, "atomvm_gleam_emscripten_ffi", "run_script")
pub fn run_script(script: String) -> Result(Nil, Error)

/// Run a script with options (`MainThread`, `Async`).
///
/// Gleam cannot overload by arity; this is Erlang `run_script/2`.
///
/// See [`emscripten:run_script/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#run_script-2).
pub fn run_script_with(
  script: String,
  options: List(RunScriptOption),
) -> Result(Nil, Error) {
  run_script_opts_ffi(script, options)
}

/// Run a script on the main thread and return tracked handles for the JS
/// values it evaluates to (default hook expects an array).
///
/// See [`emscripten:run_script_tracked/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#run_script_tracked-1).
@external(erlang, "atomvm_gleam_emscripten_ffi", "run_script_tracked")
pub fn run_script_tracked(script: String) -> Result(List(TrackedObject), Error)

/// Get keys or current string values of tracked object handles.
///
/// `TrackedKey` returns integer map keys (no main-thread round-trip).
/// `TrackedValue` fetches UTF-8 string values via the main-thread hook.
///
/// See [`emscripten:get_tracked/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#get_tracked-2).
pub fn get_tracked(
  objects: List(TrackedObject),
  field: TrackedField,
) -> Result(GetTracked, Error) {
  get_tracked_ffi(objects, field)
}

/// Resolve a promise with `0` (default success value).
///
/// Gleam cannot overload by arity; this is Erlang `promise_resolve/1`.
///
/// See [`emscripten:promise_resolve/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#promise_resolve-1).
@external(erlang, "atomvm_gleam_emscripten_ffi", "promise_resolve")
pub fn promise_resolve(promise: Promise) -> Result(Nil, Error)

/// Resolve a promise with an integer or string value.
///
/// Gleam cannot overload by arity; this is Erlang `promise_resolve/2`.
///
/// See [`emscripten:promise_resolve/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#promise_resolve-2).
pub fn promise_resolve_with(
  promise: Promise,
  value: PromiseValue,
) -> Result(Nil, Error) {
  promise_resolve_value_ffi(promise, value)
}

/// Reject a promise with `0` (default rejection value).
///
/// Gleam cannot overload by arity; this is Erlang `promise_reject/1`.
///
/// See [`emscripten:promise_reject/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#promise_reject-1).
@external(erlang, "atomvm_gleam_emscripten_ffi", "promise_reject")
pub fn promise_reject(promise: Promise) -> Result(Nil, Error)

/// Reject a promise with an integer or string value.
///
/// Gleam cannot overload by arity; this is Erlang `promise_reject/2`.
///
/// See [`emscripten:promise_reject/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#promise_reject-2).
pub fn promise_reject_with(
  promise: Promise,
  value: PromiseValue,
) -> Result(Nil, Error) {
  promise_reject_value_ffi(promise, value)
}

@external(erlang, "atomvm_gleam_emscripten_ffi", "run_script_opts")
fn run_script_opts_ffi(
  script: String,
  options: List(RunScriptOption),
) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "get_tracked")
fn get_tracked_ffi(
  objects: List(TrackedObject),
  field: TrackedField,
) -> Result(GetTracked, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "promise_resolve_value")
fn promise_resolve_value_ffi(
  promise: Promise,
  value: PromiseValue,
) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "promise_reject_value")
fn promise_reject_value_ffi(
  promise: Promise,
  value: PromiseValue,
) -> Result(Nil, Error)
