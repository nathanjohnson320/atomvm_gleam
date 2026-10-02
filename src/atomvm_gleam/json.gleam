/// Wrappers for AtomVM's OTP-compatible `json` module.
///
/// See [Module json](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).

/// Errors from JSON encode/decode.
pub type Error {
  Failed
  Badarg
  Other(String)
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    Badarg -> "badarg"
    Other(reason) -> reason
  }
}

/// Encode a term to a JSON binary (`json:encode/1` → iolist flattened).
///
/// See [`json:encode/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode")
pub fn encode(term: a) -> Result(BitArray, Error)

/// Decode a JSON binary to an Erlang term.
///
/// See [`json:decode/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "decode")
pub fn decode(bytes: BitArray) -> Result(a, Error)
