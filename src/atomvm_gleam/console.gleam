/// Console output wrappers for AtomVM `console`.
///
/// Writes are not suffixed with a newline unless the caller includes one.
///
/// Upstream: [`console.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/console.erl)
/// · Docs: [Module console](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/console.html)
/// Errors from console operations.
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

/// Ensure the console port is started and registered.
///
/// Usually unnecessary — [`puts`](#puts) / [`flush`](#flush) start it on
/// demand — but useful for eager initialization.
///
/// See [`console:start/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/console.html#start-0).
@external(erlang, "atomvm_gleam_console_ffi", "start")
pub fn start() -> Result(Nil, Error)

/// Write a string to the console (no trailing newline unless present in `text`).
///
/// See [`console:puts/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/console.html#puts-1).
@external(erlang, "atomvm_gleam_console_ffi", "puts")
pub fn puts(text: String) -> Result(Nil, Error)

/// Write a string to the console (NIF path; no trailing newline unless present).
///
/// See [`console:print/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/console.html#print-1).
@external(erlang, "atomvm_gleam_console_ffi", "print")
pub fn print(text: String) -> Result(Nil, Error)

/// Flush previously written console data.
///
/// See [`console:flush/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/console.html#flush-0).
@external(erlang, "atomvm_gleam_console_ffi", "flush")
pub fn flush() -> Result(Nil, Error)

/// Write a string to standard error (no trailing newline unless present in `text`).
///
/// Added in AtomVM 0.7 beta.
///
/// See [`console:print_err/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/console.html#print-err-1).
@external(erlang, "atomvm_gleam_console_ffi", "print_err")
pub fn print_err(text: String) -> Result(Nil, Error)
