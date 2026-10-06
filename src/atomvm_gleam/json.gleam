/// Wrappers for AtomVM's OTP-compatible `json` module.
///
/// Source: [`json.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/estdlib/src/json.erl).
/// Docs: [Module json](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
///
/// Decode returns Erlang terms (maps, lists, binaries, numbers, booleans,
/// `null`) — same as today; this module does not invent a parallel JSON AST.
///
/// Encode helpers that take an [`Encoder`](#Encoder) use the default OTP
/// encoder from [`default_encoder`](#default_encoder) (`fun json:encode_value/2`).
/// Custom encoder/decoder callback funs are not expressible cleanly from Gleam
/// and are not wrapped; pass only the opaque defaults (or Erlang funs obtained
/// outside this API).
/// Opaque OTP `encoder()` — use [`default_encoder`](#default_encoder).
pub type Encoder

/// Opaque OTP `decoders()` map — use [`default_decoders`](#default_decoders)
/// for the empty map (OTP built-in callbacks).
pub type Decoders

/// Opaque `continuation_state()` from streaming decode.
pub type Continuation

/// Input for [`decode_continue`](#decode_continue).
pub type ContinueInput {
  /// Next JSON chunk (`binary()`).
  Bytes(BitArray)
  /// Finalize a partial decode (`end_of_input`).
  EndOfInput
}

/// Result of [`decode_start`](#decode_start) / [`decode_continue`](#decode_continue).
pub type DecodeProgress(result, acc) {
  /// Finished value, updated accumulator, and unconsumed trailing bytes.
  Complete(result, acc, BitArray)
  /// Need another chunk (or [`EndOfInput`](#ContinueInput)).
  NeedMore(Continuation)
}

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

/// Default OTP encoder (`fun json:encode_value/2`).
///
/// See [`json:encode/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "default_encoder")
pub fn default_encoder() -> Encoder

/// Empty decoder options map (`#{}`) — OTP default callbacks for arrays,
/// objects, floats, integers, strings, and `null`.
///
/// See [`json:decode/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "default_decoders")
pub fn default_decoders() -> Decoders

/// Encode a term to a JSON binary (`json:encode/1` → iolist flattened).
///
/// See [`json:encode/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode")
pub fn encode(term: a) -> Result(BitArray, Error)

/// Encode with an explicit encoder callback (`json:encode/2`).
///
/// Prefer [`default_encoder`](#default_encoder) unless you have an Erlang
/// `encoder()` fun from elsewhere.
///
/// See [`json:encode/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_with")
pub fn encode_with(term: a, encoder: Encoder) -> Result(BitArray, Error)

/// Encode a value by dispatching on its Erlang type (`json:encode_value/2`).
///
/// See [`json:encode_value/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_value")
pub fn encode_value(term: a, encoder: Encoder) -> Result(BitArray, Error)

/// Encode an atom (`null` / `true` / `false`, or via the encoder as a string).
///
/// See [`json:encode_atom/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_atom")
pub fn encode_atom(atom: a, encoder: Encoder) -> Result(BitArray, Error)

/// Encode a binary as a JSON string (escape control / quote / backslash).
///
/// See [`json:encode_binary/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_binary")
pub fn encode_binary(bytes: BitArray) -> Result(BitArray, Error)

/// Encode a binary escaping all non-ASCII as `\uXXXX`.
///
/// See [`json:encode_binary_escape_all/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_binary_escape_all")
pub fn encode_binary_escape_all(bytes: BitArray) -> Result(BitArray, Error)

/// Encode a float (`float_to_binary` short form).
///
/// See [`json:encode_float/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_float")
pub fn encode_float(float: Float) -> Result(BitArray, Error)

/// Encode an integer.
///
/// See [`json:encode_integer/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_integer")
pub fn encode_integer(int: Int) -> Result(BitArray, Error)

/// Encode a list as a JSON array.
///
/// See [`json:encode_list/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_list")
pub fn encode_list(list: List(a), encoder: Encoder) -> Result(BitArray, Error)

/// Encode a map as a JSON object.
///
/// See [`json:encode_map/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_map")
pub fn encode_map(map: a, encoder: Encoder) -> Result(BitArray, Error)

/// Encode a map as a JSON object, rejecting duplicate keys.
///
/// See [`json:encode_map_checked/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_map_checked")
pub fn encode_map_checked(map: a, encoder: Encoder) -> Result(BitArray, Error)

/// Encode a key/value list as a JSON object.
///
/// See [`json:encode_key_value_list/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_key_value_list")
pub fn encode_key_value_list(
  pairs: List(#(k, v)),
  encoder: Encoder,
) -> Result(BitArray, Error)

/// Encode a key/value list as a JSON object, rejecting duplicate keys.
///
/// See [`json:encode_key_value_list_checked/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "encode_key_value_list_checked")
pub fn encode_key_value_list_checked(
  pairs: List(#(k, v)),
  encoder: Encoder,
) -> Result(BitArray, Error)

/// Decode a JSON binary to an Erlang term.
///
/// See [`json:decode/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "decode")
pub fn decode(bytes: BitArray) -> Result(a, Error)

/// Decode with accumulator and decoder options (`json:decode/3`).
///
/// Returns `#(value, acc, rest)`. Use [`default_decoders`](#default_decoders)
/// for OTP defaults.
///
/// See [`json:decode/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "decode_with")
pub fn decode_with(
  bytes: BitArray,
  acc: acc,
  decoders: Decoders,
) -> Result(#(result, acc, BitArray), Error)

/// Begin a streaming decode (`json:decode_start/3`).
///
/// See [`json:decode_start/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "decode_start")
pub fn decode_start(
  bytes: BitArray,
  acc: acc,
  decoders: Decoders,
) -> Result(DecodeProgress(result, acc), Error)

/// Continue a streaming decode (`json:decode_continue/2`).
///
/// See [`json:decode_continue/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/json.html).
@external(erlang, "atomvm_gleam_json_ffi", "decode_continue")
pub fn decode_continue(
  input: ContinueInput,
  state: Continuation,
) -> Result(DecodeProgress(result, acc), Error)
