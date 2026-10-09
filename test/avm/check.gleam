//// Result-based asserts for the packed AtomVM test runner.
////
//// You're probably wondering why these aren't just `assert` macros.
//// Well the reason is that the packed test runner can't use `assert` macros
//// because it needs to return `Result` values so that the flow keeps working.
//// For more info contact nate
////
//// Behavioral coverage tags: pass API ids as string literals to `cover*`
//// helpers (e.g. `"esp.freq_hz"`) to mark hard asserts.

import gleam/string

pub type Failure {
  Failure(message: String)
}

pub fn ok() -> Result(Nil, Failure) {
  Ok(Nil)
}

pub fn fail(message: String) -> Result(Nil, Failure) {
  Error(Failure(message))
}

/// Tag a hard behavioral check.
/// The `id` string literal must be `module.fn` (e.g. `"esp.freq_hz"`).
pub fn cover(id: String, result: Result(a, Failure)) -> Result(a, Failure) {
  let _ = id
  result
}

pub fn cover_ok(id: String, result: Result(a, e)) -> Result(a, Failure) {
  cover(id, assert_ok(id, result))
}

pub fn cover_eq(id: String, got: a, want: a) -> Result(Nil, Failure) {
  cover(id, assert_eq(id, got, want))
}

pub fn cover_true(id: String, value: Bool) -> Result(Nil, Failure) {
  cover(id, assert_true(id, value))
}

pub fn cover_error(id: String, result: Result(a, e)) -> Result(e, Failure) {
  cover(id, assert_error(id, result))
}

/// Hard-assert that an off-platform call returned `NotSupported`-shaped Error.
/// Callers must already have matched the error variant; this only tags + Ok.
pub fn cover_not_supported(id: String) -> Result(Nil, Failure) {
  cover(id, ok())
}

pub fn assert_true(label: String, value: Bool) -> Result(Nil, Failure) {
  case value {
    True -> Ok(Nil)
    False -> Error(Failure(label <> ": expected True"))
  }
}

pub fn assert_eq(label: String, got: a, want: a) -> Result(Nil, Failure) {
  case got == want {
    True -> Ok(Nil)
    False ->
      Error(Failure(label <> ": expected equal values (got mismatched terms)"))
  }
}

pub fn assert_ok(label: String, result: Result(a, e)) -> Result(a, Failure) {
  case result {
    Ok(value) -> Ok(value)
    Error(_) -> Error(Failure(label <> ": expected Ok"))
  }
}

pub fn assert_error(label: String, result: Result(a, e)) -> Result(e, Failure) {
  case result {
    Error(reason) -> Ok(reason)
    Ok(_) -> Error(Failure(label <> ": expected Error"))
  }
}

pub fn failure_message(failure: Failure) -> String {
  let Failure(message) = failure
  message
}

pub fn join_failures(failures: List(Failure)) -> String {
  string.join(list_map_messages(failures), with: "; ")
}

fn list_map_messages(failures: List(Failure)) -> List(String) {
  case failures {
    [] -> []
    [Failure(message), ..rest] -> [message, ..list_map_messages(rest)]
  }
}
