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
//// ## HTML5 event callbacks
////
//// Register with [`register_*_with`](#register_click_with) (target + options),
//// the no-options [`register_*`](#register_click) form, or
//// [`register_*_with_user_data`](#register_click_with_user_data) for the
//// upstream `/3` arity. Unregister with [`unregister_*`](#unregister_click)
//// using a [`ListenerHandle`](#ListenerHandle) (preferred) or
//// [`Html5Target`](#Html5Target).
////
//// ### Inbound message shape
////
//// Without user data:
//// `{emscripten, {EventName, EventMap}}`.
////
//// With user data (`register_*_with_user_data`):
//// `{emscripten, {EventName, EventMap}, UserData}` - an outer 3-tuple; the
//// third element is the term you passed at register time (copied into the
//// listener handle). User data is any Erlang term: Gleam `Int`, `String`,
//// tuples, lists, atoms via FFI, etc. Keep it small - the handle retains a
//// copy for the listener lifetime.
////
//// If the registering process dies, that callback and any other callback for
//// the same event on the same target are unregistered (upstream behaviour).
////
//// ### HTML5 exports
////
//// Keyboard: keypress, keydown, keyup.
//// Mouse: click, dblclick, mousedown, mouseup, mousemove, mouseenter,
//// mouseleave, mouseover, mouseout.
//// Other: wheel, resize, scroll, blur, focus, focusin, focusout, touchstart,
//// touchend, touchmove, touchcancel.
////
//// Upstream:
//// [`libs/avm_emscripten/src/emscripten.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_emscripten/src/emscripten.erl)
//// · Docs:
//// [Module emscripten](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html)

import gleam/int

/// Opaque promise resource from `{emscripten, {call, Promise, Msg}}`.
///
/// Pass to [`promise_resolve`](#promise_resolve) or
/// [`promise_reject`](#promise_reject). Upstream type is an opaque binary.
pub type Promise

/// Opaque handle to a JavaScript value kept alive in `Module.trackedObjectsMap`
/// until this term is garbage-collected.
pub type TrackedObject

/// Opaque listener resource from a successful HTML5 register call.
///
/// Prefer passing this to unregister over a bare target so the handle can be
/// garbage-collected. Upstream type is an opaque binary.
pub type ListenerHandle

/// Errors from emscripten NIFs and helpers.
///
/// Known reason atoms are Gleam constructors (so `{error, not_supported}` is
/// `Error(NotSupported)`). Bare AtomVM `error` becomes `Failed`. Integer
/// HTML5 register codes become `Code(n)`. Anything else lands in `Other`.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  InvalidTarget
  UnknownTarget
  FailedNotDeferred
  NoData
  TimedOut
  Code(Int)
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

/// HTML5 register target. Maps to Erlang `window` / `document` / `screen`
/// or a CSS selector string (iodata).
///
/// `Screen` is accepted by upstream but may not deliver events
/// ([emscripten#19865](https://github.com/emscripten-core/emscripten/issues/19865)).
pub type Html5Target {
  Window
  Document
  Screen
  CssSelector(String)
}

/// Single option for HTML5 register calls.
///
/// Maps to Erlang `{use_capture, Bool}` / `{prevent_default, Bool}`.
/// `PreventDefault(True)` means the handler tells JavaScript to prevent the
/// default action.
pub type RegisterOption {
  UseCapture(Bool)
  PreventDefault(Bool)
}

/// Successful HTML5 register result.
///
/// Upstream `{ok, Handle}` → `Registered`; `{ok, Handle, deferred}` →
/// `Deferred` (listener queued until the main thread applied it).
pub type RegisterOk {
  Registered(ListenerHandle)
  Deferred(ListenerHandle)
}

/// Argument to HTML5 unregister: a listener handle (preferred) or a target.
///
/// Unregistering by target removes every listener for that event on the
/// target. Passing a handle is recommended for memory efficiency.
pub type ListenerOrTarget {
  Handle(ListenerHandle)
  Target(Html5Target)
}

/// Keyboard event map from keypress / keydown / keyup.
///
/// Delivered as `{emscripten, {keypress | keydown | keyup, Event}}`.
/// Erlang map keys: `timestamp` (Float), `location` (Int), `ctrl_key` /
/// `shift_key` / `alt_key` / `meta_key` / `repeat` (Bool), `char_code` /
/// `key_code` / `which` (Int), `key` / `code` / `char_value` / `locale`
/// (UTF-8 binary).
pub type KeyboardEvent

/// Mouse event map from click / dblclick / mouse* callbacks.
///
/// Delivered as `{emscripten, {click | …, Event}}`.
/// Keys: `timestamp` (Float), `screen_x` / `screen_y` / `client_x` /
/// `client_y` / `button` / `buttons` / `movement_x` / `movement_y` /
/// `target_x` / `target_y` / `padding` (Int), `ctrl_key` / `shift_key` /
/// `alt_key` / `meta_key` (Bool).
pub type MouseEvent

/// Wheel event map (extends mouse fields with deltas).
///
/// Keys: all [`MouseEvent`](#MouseEvent) keys plus `delta_x` / `delta_y` /
/// `delta_z` / `delta_mode` (Int).
pub type WheelEvent

/// UI event map from resize / scroll.
///
/// Keys: `detail`, `document_body_client_width` /
/// `document_body_client_height`, `window_inner_width` /
/// `window_inner_height`, `window_outer_width` / `window_outer_height`,
/// `scroll_top` / `scroll_left` (all Int).
pub type UiEvent

/// Focus event map from blur / focus / focusin / focusout.
///
/// Keys: `node_name` / `id` (UTF-8 binary).
pub type FocusEvent

/// Touch event map from touchstart / touchend / touchmove / touchcancel.
///
/// Keys: `timestamp` (Float), `ctrl_key` / `shift_key` / `alt_key` /
/// `meta_key` (Bool), `touches` (list of touch-point maps with
/// `identifier`, `screen_x` / `screen_y`, `client_x` / `client_y`,
/// `page_x` / `page_y`, `is_changed` / `on_target`, `target_x` /
/// `target_y`).
pub type TouchEvent

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    InvalidTarget -> "invalid_target"
    UnknownTarget -> "unknown_target"
    FailedNotDeferred -> "failed_not_deferred"
    NoData -> "no_data"
    TimedOut -> "timed_out"
    Code(n) -> "code:" <> int.to_string(n)
    Other(reason) -> reason
  }
}

/// Run a script on the current worker thread (rarely useful alone).
///
/// Prefer [`run_script_with`](#run_script_with) with `[MainThread]` or
/// `[MainThread, Async]`. Exception handling is disabled - a throw or compile
/// error crashes the VM.
///
/// See [`emscripten:run_script/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#run_script-1).
@external(erlang, "atomvm_gleam_emscripten_ffi", "run_script")
pub fn run_script(script: String) -> Result(Nil, Error)

/// Run a script with options (`MainThread`, `Async`).
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
/// See [`emscripten:promise_resolve/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#promise_resolve-1).
@external(erlang, "atomvm_gleam_emscripten_ffi", "promise_resolve")
pub fn promise_resolve(promise: Promise) -> Result(Nil, Error)

/// Resolve a promise with an integer or string value.
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
/// See [`emscripten:promise_reject/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#promise_reject-1).
@external(erlang, "atomvm_gleam_emscripten_ffi", "promise_reject")
pub fn promise_reject(promise: Promise) -> Result(Nil, Error)

/// Reject a promise with an integer or string value.
///
/// See [`emscripten:promise_reject/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#promise_reject-2).
pub fn promise_reject_with(
  promise: Promise,
  value: PromiseValue,
) -> Result(Nil, Error) {
  promise_reject_value_ffi(promise, value)
}

// --- HTML5: keyboard -------------------------------------------------------

/// Register keypress with default options.
///
/// Events: `{emscripten, {keypress, KeyboardEvent}}`. Dying processes
/// unregister callbacks for this event/target.
///
/// See [`emscripten:register_keypress_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_keypress_callback-1).
pub fn register_keypress(target: Html5Target) -> Result(RegisterOk, Error) {
  register_keypress_with(target, [])
}

/// Register keypress with options (`UseCapture`, `PreventDefault`).
///
/// See [`emscripten:register_keypress_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_keypress_callback-2).
pub fn register_keypress_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_keypress_ffi(target, options)
}

/// Register keypress with options and user data.
///
/// Events: `{emscripten, {keypress, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {keypress, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_keypress_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_keypress_callback-3).
pub fn register_keypress_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_keypress_user_data_ffi(target, options, user_data)
}

/// Unregister keypress listeners (by handle or target).
///
/// See [`emscripten:unregister_keypress_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_keypress_callback-1).
pub fn unregister_keypress(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_keypress_ffi(arg)
}

/// Register keydown with default options.
///
/// See [`emscripten:register_keydown_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_keydown_callback-1).
pub fn register_keydown(target: Html5Target) -> Result(RegisterOk, Error) {
  register_keydown_with(target, [])
}

/// Register keydown with options.
///
/// See [`emscripten:register_keydown_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_keydown_callback-2).
pub fn register_keydown_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_keydown_ffi(target, options)
}

/// Register keydown with options and user data.
///
/// Events: `{emscripten, {keydown, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {keydown, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_keydown_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_keydown_callback-3).
pub fn register_keydown_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_keydown_user_data_ffi(target, options, user_data)
}

/// Unregister keydown listeners.
///
/// See [`emscripten:unregister_keydown_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_keydown_callback-1).
pub fn unregister_keydown(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_keydown_ffi(arg)
}

/// Register keyup with default options.
///
/// See [`emscripten:register_keyup_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_keyup_callback-1).
pub fn register_keyup(target: Html5Target) -> Result(RegisterOk, Error) {
  register_keyup_with(target, [])
}

/// Register keyup with options.
///
/// See [`emscripten:register_keyup_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_keyup_callback-2).
pub fn register_keyup_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_keyup_ffi(target, options)
}

/// Register keyup with options and user data.
///
/// Events: `{emscripten, {keyup, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {keyup, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_keyup_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_keyup_callback-3).
pub fn register_keyup_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_keyup_user_data_ffi(target, options, user_data)
}

/// Unregister keyup listeners.
///
/// See [`emscripten:unregister_keyup_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_keyup_callback-1).
pub fn unregister_keyup(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_keyup_ffi(arg)
}

// --- HTML5: mouse -----------------------------------------------------------

/// Register click with default options.
///
/// Events: `{emscripten, {click, MouseEvent}}`.
///
/// See [`emscripten:register_click_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_click_callback-1).
pub fn register_click(target: Html5Target) -> Result(RegisterOk, Error) {
  register_click_with(target, [])
}

/// Register click with options.
///
/// See [`emscripten:register_click_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_click_callback-2).
pub fn register_click_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_click_ffi(target, options)
}

/// Register click with options and user data.
///
/// Events: `{emscripten, {click, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {click, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_click_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_click_callback-3).
pub fn register_click_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_click_user_data_ffi(target, options, user_data)
}

/// Unregister click listeners.
///
/// See [`emscripten:unregister_click_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_click_callback-1).
pub fn unregister_click(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_click_ffi(arg)
}

/// Register dblclick with default options.
///
/// See [`emscripten:register_dblclick_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_dblclick_callback-1).
pub fn register_dblclick(target: Html5Target) -> Result(RegisterOk, Error) {
  register_dblclick_with(target, [])
}

/// Register dblclick with options.
///
/// See [`emscripten:register_dblclick_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_dblclick_callback-2).
pub fn register_dblclick_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_dblclick_ffi(target, options)
}

/// Register dblclick with options and user data.
///
/// Events: `{emscripten, {dblclick, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {dblclick, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_dblclick_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_dblclick_callback-3).
pub fn register_dblclick_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_dblclick_user_data_ffi(target, options, user_data)
}

/// Unregister dblclick listeners.
///
/// See [`emscripten:unregister_dblclick_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_dblclick_callback-1).
pub fn unregister_dblclick(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_dblclick_ffi(arg)
}

/// Register mousedown with default options.
///
/// See [`emscripten:register_mousedown_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mousedown_callback-1).
pub fn register_mousedown(target: Html5Target) -> Result(RegisterOk, Error) {
  register_mousedown_with(target, [])
}

/// Register mousedown with options.
///
/// See [`emscripten:register_mousedown_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mousedown_callback-2).
pub fn register_mousedown_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_mousedown_ffi(target, options)
}

/// Register mousedown with options and user data.
///
/// Events: `{emscripten, {mousedown, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {mousedown, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_mousedown_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mousedown_callback-3).
pub fn register_mousedown_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_mousedown_user_data_ffi(target, options, user_data)
}

/// Unregister mousedown listeners.
///
/// See [`emscripten:unregister_mousedown_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_mousedown_callback-1).
pub fn unregister_mousedown(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_mousedown_ffi(arg)
}

/// Register mouseup with default options.
///
/// See [`emscripten:register_mouseup_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseup_callback-1).
pub fn register_mouseup(target: Html5Target) -> Result(RegisterOk, Error) {
  register_mouseup_with(target, [])
}

/// Register mouseup with options.
///
/// See [`emscripten:register_mouseup_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseup_callback-2).
pub fn register_mouseup_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_mouseup_ffi(target, options)
}

/// Register mouseup with options and user data.
///
/// Events: `{emscripten, {mouseup, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {mouseup, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_mouseup_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseup_callback-3).
pub fn register_mouseup_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_mouseup_user_data_ffi(target, options, user_data)
}

/// Unregister mouseup listeners.
///
/// See [`emscripten:unregister_mouseup_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_mouseup_callback-1).
pub fn unregister_mouseup(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_mouseup_ffi(arg)
}

/// Register mousemove with default options.
///
/// See [`emscripten:register_mousemove_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mousemove_callback-1).
pub fn register_mousemove(target: Html5Target) -> Result(RegisterOk, Error) {
  register_mousemove_with(target, [])
}

/// Register mousemove with options.
///
/// See [`emscripten:register_mousemove_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mousemove_callback-2).
pub fn register_mousemove_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_mousemove_ffi(target, options)
}

/// Register mousemove with options and user data.
///
/// Events: `{emscripten, {mousemove, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {mousemove, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_mousemove_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mousemove_callback-3).
pub fn register_mousemove_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_mousemove_user_data_ffi(target, options, user_data)
}

/// Unregister mousemove listeners.
///
/// See [`emscripten:unregister_mousemove_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_mousemove_callback-1).
pub fn unregister_mousemove(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_mousemove_ffi(arg)
}

/// Register mouseenter with default options.
///
/// See [`emscripten:register_mouseenter_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseenter_callback-1).
pub fn register_mouseenter(target: Html5Target) -> Result(RegisterOk, Error) {
  register_mouseenter_with(target, [])
}

/// Register mouseenter with options.
///
/// See [`emscripten:register_mouseenter_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseenter_callback-2).
pub fn register_mouseenter_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_mouseenter_ffi(target, options)
}

/// Register mouseenter with options and user data.
///
/// Events: `{emscripten, {mouseenter, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {mouseenter, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_mouseenter_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseenter_callback-3).
pub fn register_mouseenter_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_mouseenter_user_data_ffi(target, options, user_data)
}

/// Unregister mouseenter listeners.
///
/// See [`emscripten:unregister_mouseenter_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_mouseenter_callback-1).
pub fn unregister_mouseenter(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_mouseenter_ffi(arg)
}

/// Register mouseleave with default options.
///
/// See [`emscripten:register_mouseleave_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseleave_callback-1).
pub fn register_mouseleave(target: Html5Target) -> Result(RegisterOk, Error) {
  register_mouseleave_with(target, [])
}

/// Register mouseleave with options.
///
/// See [`emscripten:register_mouseleave_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseleave_callback-2).
pub fn register_mouseleave_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_mouseleave_ffi(target, options)
}

/// Register mouseleave with options and user data.
///
/// Events: `{emscripten, {mouseleave, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {mouseleave, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_mouseleave_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseleave_callback-3).
pub fn register_mouseleave_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_mouseleave_user_data_ffi(target, options, user_data)
}

/// Unregister mouseleave listeners.
///
/// See [`emscripten:unregister_mouseleave_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_mouseleave_callback-1).
pub fn unregister_mouseleave(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_mouseleave_ffi(arg)
}

/// Register mouseover with default options.
///
/// See [`emscripten:register_mouseover_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseover_callback-1).
pub fn register_mouseover(target: Html5Target) -> Result(RegisterOk, Error) {
  register_mouseover_with(target, [])
}

/// Register mouseover with options.
///
/// See [`emscripten:register_mouseover_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseover_callback-2).
pub fn register_mouseover_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_mouseover_ffi(target, options)
}

/// Register mouseover with options and user data.
///
/// Events: `{emscripten, {mouseover, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {mouseover, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_mouseover_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseover_callback-3).
pub fn register_mouseover_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_mouseover_user_data_ffi(target, options, user_data)
}

/// Unregister mouseover listeners.
///
/// See [`emscripten:unregister_mouseover_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_mouseover_callback-1).
pub fn unregister_mouseover(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_mouseover_ffi(arg)
}

/// Register mouseout with default options.
///
/// See [`emscripten:register_mouseout_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseout_callback-1).
pub fn register_mouseout(target: Html5Target) -> Result(RegisterOk, Error) {
  register_mouseout_with(target, [])
}

/// Register mouseout with options.
///
/// See [`emscripten:register_mouseout_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseout_callback-2).
pub fn register_mouseout_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_mouseout_ffi(target, options)
}

/// Register mouseout with options and user data.
///
/// Events: `{emscripten, {mouseout, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {mouseout, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_mouseout_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_mouseout_callback-3).
pub fn register_mouseout_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_mouseout_user_data_ffi(target, options, user_data)
}

/// Unregister mouseout listeners.
///
/// See [`emscripten:unregister_mouseout_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_mouseout_callback-1).
pub fn unregister_mouseout(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_mouseout_ffi(arg)
}

// --- HTML5: wheel / ui / focus / touch --------------------------------------

/// Register wheel with default options.
///
/// Events: `{emscripten, {wheel, WheelEvent}}`.
///
/// See [`emscripten:register_wheel_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_wheel_callback-1).
pub fn register_wheel(target: Html5Target) -> Result(RegisterOk, Error) {
  register_wheel_with(target, [])
}

/// Register wheel with options.
///
/// See [`emscripten:register_wheel_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_wheel_callback-2).
pub fn register_wheel_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_wheel_ffi(target, options)
}

/// Register wheel with options and user data.
///
/// Events: `{emscripten, {wheel, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {wheel, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_wheel_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_wheel_callback-3).
pub fn register_wheel_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_wheel_user_data_ffi(target, options, user_data)
}

/// Unregister wheel listeners.
///
/// See [`emscripten:unregister_wheel_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_wheel_callback-1).
pub fn unregister_wheel(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_wheel_ffi(arg)
}

/// Register resize with default options.
///
/// Events: `{emscripten, {resize, UiEvent}}`.
///
/// See [`emscripten:register_resize_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_resize_callback-1).
pub fn register_resize(target: Html5Target) -> Result(RegisterOk, Error) {
  register_resize_with(target, [])
}

/// Register resize with options.
///
/// See [`emscripten:register_resize_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_resize_callback-2).
pub fn register_resize_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_resize_ffi(target, options)
}

/// Register resize with options and user data.
///
/// Events: `{emscripten, {resize, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {resize, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_resize_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_resize_callback-3).
pub fn register_resize_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_resize_user_data_ffi(target, options, user_data)
}

/// Unregister resize listeners.
///
/// See [`emscripten:unregister_resize_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_resize_callback-1).
pub fn unregister_resize(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_resize_ffi(arg)
}

/// Register scroll with default options.
///
/// Events: `{emscripten, {scroll, UiEvent}}`.
///
/// See [`emscripten:register_scroll_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_scroll_callback-1).
pub fn register_scroll(target: Html5Target) -> Result(RegisterOk, Error) {
  register_scroll_with(target, [])
}

/// Register scroll with options.
///
/// See [`emscripten:register_scroll_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_scroll_callback-2).
pub fn register_scroll_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_scroll_ffi(target, options)
}

/// Register scroll with options and user data.
///
/// Events: `{emscripten, {scroll, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {scroll, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_scroll_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_scroll_callback-3).
pub fn register_scroll_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_scroll_user_data_ffi(target, options, user_data)
}

/// Unregister scroll listeners.
///
/// See [`emscripten:unregister_scroll_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_scroll_callback-1).
pub fn unregister_scroll(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_scroll_ffi(arg)
}

/// Register blur with default options.
///
/// Events: `{emscripten, {blur, FocusEvent}}`.
///
/// See [`emscripten:register_blur_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_blur_callback-1).
pub fn register_blur(target: Html5Target) -> Result(RegisterOk, Error) {
  register_blur_with(target, [])
}

/// Register blur with options.
///
/// See [`emscripten:register_blur_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_blur_callback-2).
pub fn register_blur_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_blur_ffi(target, options)
}

/// Register blur with options and user data.
///
/// Events: `{emscripten, {blur, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {blur, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_blur_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_blur_callback-3).
pub fn register_blur_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_blur_user_data_ffi(target, options, user_data)
}

/// Unregister blur listeners.
///
/// See [`emscripten:unregister_blur_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_blur_callback-1).
pub fn unregister_blur(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_blur_ffi(arg)
}

/// Register focus with default options.
///
/// See [`emscripten:register_focus_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_focus_callback-1).
pub fn register_focus(target: Html5Target) -> Result(RegisterOk, Error) {
  register_focus_with(target, [])
}

/// Register focus with options.
///
/// See [`emscripten:register_focus_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_focus_callback-2).
pub fn register_focus_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_focus_ffi(target, options)
}

/// Register focus with options and user data.
///
/// Events: `{emscripten, {focus, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {focus, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_focus_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_focus_callback-3).
pub fn register_focus_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_focus_user_data_ffi(target, options, user_data)
}

/// Unregister focus listeners.
///
/// See [`emscripten:unregister_focus_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_focus_callback-1).
pub fn unregister_focus(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_focus_ffi(arg)
}

/// Register focusin with default options.
///
/// See [`emscripten:register_focusin_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_focusin_callback-1).
pub fn register_focusin(target: Html5Target) -> Result(RegisterOk, Error) {
  register_focusin_with(target, [])
}

/// Register focusin with options.
///
/// See [`emscripten:register_focusin_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_focusin_callback-2).
pub fn register_focusin_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_focusin_ffi(target, options)
}

/// Register focusin with options and user data.
///
/// Events: `{emscripten, {focusin, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {focusin, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_focusin_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_focusin_callback-3).
pub fn register_focusin_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_focusin_user_data_ffi(target, options, user_data)
}

/// Unregister focusin listeners.
///
/// See [`emscripten:unregister_focusin_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_focusin_callback-1).
pub fn unregister_focusin(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_focusin_ffi(arg)
}

/// Register focusout with default options.
///
/// See [`emscripten:register_focusout_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_focusout_callback-1).
pub fn register_focusout(target: Html5Target) -> Result(RegisterOk, Error) {
  register_focusout_with(target, [])
}

/// Register focusout with options.
///
/// See [`emscripten:register_focusout_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_focusout_callback-2).
pub fn register_focusout_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_focusout_ffi(target, options)
}

/// Register focusout with options and user data.
///
/// Events: `{emscripten, {focusout, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {focusout, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_focusout_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_focusout_callback-3).
pub fn register_focusout_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_focusout_user_data_ffi(target, options, user_data)
}

/// Unregister focusout listeners.
///
/// See [`emscripten:unregister_focusout_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_focusout_callback-1).
pub fn unregister_focusout(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_focusout_ffi(arg)
}

/// Register touchstart with default options.
///
/// Events: `{emscripten, {touchstart, TouchEvent}}`.
///
/// See [`emscripten:register_touchstart_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchstart_callback-1).
pub fn register_touchstart(target: Html5Target) -> Result(RegisterOk, Error) {
  register_touchstart_with(target, [])
}

/// Register touchstart with options.
///
/// See [`emscripten:register_touchstart_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchstart_callback-2).
pub fn register_touchstart_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_touchstart_ffi(target, options)
}

/// Register touchstart with options and user data.
///
/// Events: `{emscripten, {touchstart, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {touchstart, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_touchstart_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchstart_callback-3).
pub fn register_touchstart_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_touchstart_user_data_ffi(target, options, user_data)
}

/// Unregister touchstart listeners.
///
/// See [`emscripten:unregister_touchstart_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_touchstart_callback-1).
pub fn unregister_touchstart(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_touchstart_ffi(arg)
}

/// Register touchend with default options.
///
/// See [`emscripten:register_touchend_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchend_callback-1).
pub fn register_touchend(target: Html5Target) -> Result(RegisterOk, Error) {
  register_touchend_with(target, [])
}

/// Register touchend with options.
///
/// See [`emscripten:register_touchend_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchend_callback-2).
pub fn register_touchend_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_touchend_ffi(target, options)
}

/// Register touchend with options and user data.
///
/// Events: `{emscripten, {touchend, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {touchend, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_touchend_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchend_callback-3).
pub fn register_touchend_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_touchend_user_data_ffi(target, options, user_data)
}

/// Unregister touchend listeners.
///
/// See [`emscripten:unregister_touchend_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_touchend_callback-1).
pub fn unregister_touchend(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_touchend_ffi(arg)
}

/// Register touchmove with default options.
///
/// See [`emscripten:register_touchmove_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchmove_callback-1).
pub fn register_touchmove(target: Html5Target) -> Result(RegisterOk, Error) {
  register_touchmove_with(target, [])
}

/// Register touchmove with options.
///
/// See [`emscripten:register_touchmove_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchmove_callback-2).
pub fn register_touchmove_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_touchmove_ffi(target, options)
}

/// Register touchmove with options and user data.
///
/// Events: `{emscripten, {touchmove, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {touchmove, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_touchmove_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchmove_callback-3).
pub fn register_touchmove_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_touchmove_user_data_ffi(target, options, user_data)
}

/// Unregister touchmove listeners.
///
/// See [`emscripten:unregister_touchmove_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_touchmove_callback-1).
pub fn unregister_touchmove(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_touchmove_ffi(arg)
}

/// Register touchcancel with default options.
///
/// See [`emscripten:register_touchcancel_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchcancel_callback-1).
pub fn register_touchcancel(target: Html5Target) -> Result(RegisterOk, Error) {
  register_touchcancel_with(target, [])
}

/// Register touchcancel with options.
///
/// See [`emscripten:register_touchcancel_callback/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchcancel_callback-2).
pub fn register_touchcancel_with(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error) {
  register_touchcancel_ffi(target, options)
}

/// Register touchcancel with options and user data.
///
/// Events: `{emscripten, {touchcancel, Event}, UserData}` (outer 3-tuple).
/// Without user data the shape is `{emscripten, {touchcancel, Event}}`.
/// `user_data` is any Erlang term; the listener handle retains a copy.
///
/// See [`emscripten:register_touchcancel_callback/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#register_touchcancel_callback-3).
pub fn register_touchcancel_with_user_data(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error) {
  register_touchcancel_user_data_ffi(target, options, user_data)
}

/// Unregister touchcancel listeners.
///
/// See [`emscripten:unregister_touchcancel_callback/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/avm_emscripten/emscripten.html#unregister_touchcancel_callback-1).
pub fn unregister_touchcancel(arg: ListenerOrTarget) -> Result(Nil, Error) {
  unregister_touchcancel_ffi(arg)
}

// --- FFI --------------------------------------------------------------------

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

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_keypress")
fn register_keypress_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_keypress")
fn unregister_keypress_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_keydown")
fn register_keydown_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_keydown")
fn unregister_keydown_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_keyup")
fn register_keyup_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_keyup")
fn unregister_keyup_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_click")
fn register_click_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_click")
fn unregister_click_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_dblclick")
fn register_dblclick_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_dblclick")
fn unregister_dblclick_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mousedown")
fn register_mousedown_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_mousedown")
fn unregister_mousedown_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mouseup")
fn register_mouseup_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_mouseup")
fn unregister_mouseup_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mousemove")
fn register_mousemove_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_mousemove")
fn unregister_mousemove_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mouseenter")
fn register_mouseenter_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_mouseenter")
fn unregister_mouseenter_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mouseleave")
fn register_mouseleave_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_mouseleave")
fn unregister_mouseleave_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mouseover")
fn register_mouseover_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_mouseover")
fn unregister_mouseover_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mouseout")
fn register_mouseout_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_mouseout")
fn unregister_mouseout_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_wheel")
fn register_wheel_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_wheel")
fn unregister_wheel_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_resize")
fn register_resize_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_resize")
fn unregister_resize_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_scroll")
fn register_scroll_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_scroll")
fn unregister_scroll_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_blur")
fn register_blur_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_blur")
fn unregister_blur_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_focus")
fn register_focus_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_focus")
fn unregister_focus_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_focusin")
fn register_focusin_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_focusin")
fn unregister_focusin_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_focusout")
fn register_focusout_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_focusout")
fn unregister_focusout_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_touchstart")
fn register_touchstart_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_touchstart")
fn unregister_touchstart_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_touchend")
fn register_touchend_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_touchend")
fn unregister_touchend_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_touchmove")
fn register_touchmove_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_touchmove")
fn unregister_touchmove_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_touchcancel")
fn register_touchcancel_ffi(
  target: Html5Target,
  options: List(RegisterOption),
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "unregister_touchcancel")
fn unregister_touchcancel_ffi(arg: ListenerOrTarget) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_keypress_user_data")
fn register_keypress_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_keydown_user_data")
fn register_keydown_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_keyup_user_data")
fn register_keyup_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_click_user_data")
fn register_click_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_dblclick_user_data")
fn register_dblclick_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mousedown_user_data")
fn register_mousedown_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mouseup_user_data")
fn register_mouseup_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mousemove_user_data")
fn register_mousemove_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mouseenter_user_data")
fn register_mouseenter_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mouseleave_user_data")
fn register_mouseleave_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mouseover_user_data")
fn register_mouseover_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_mouseout_user_data")
fn register_mouseout_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_wheel_user_data")
fn register_wheel_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_resize_user_data")
fn register_resize_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_scroll_user_data")
fn register_scroll_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_blur_user_data")
fn register_blur_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_focus_user_data")
fn register_focus_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_focusin_user_data")
fn register_focusin_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_focusout_user_data")
fn register_focusout_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_touchstart_user_data")
fn register_touchstart_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_touchend_user_data")
fn register_touchend_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_touchmove_user_data")
fn register_touchmove_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "register_touchcancel_user_data")
fn register_touchcancel_user_data_ffi(
  target: Html5Target,
  options: List(RegisterOption),
  user_data: user_data,
) -> Result(RegisterOk, Error)
