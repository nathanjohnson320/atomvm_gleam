/// AtomVM platform helpers (`atomvm` module).
///
/// See [Module atomvm](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html).
import gleam/option.{type Option}

/// Errors from AtomVM platform helpers.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  NotFound
  Undefined
  Other(String)
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    NotFound -> "not_found"
    Undefined -> "undefined"
    Other(reason) -> reason
  }
}

/// Mount an AVM pack file (or ESP32 partition path) under `name`.
///
/// On ESP32, `path` is typically `"/dev/partition/by-name/assets.avm"`.
/// `name` becomes the Erlang atom used with [`read_priv`](#read_priv).
///
/// See [`atomvm:add_avm_pack_file/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#add-avm-pack-file-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "add_avm_pack_file")
pub fn add_avm_pack_file(path: String, name: String) -> Result(Nil, Error)

/// Read a `priv/` resource from a previously mounted AVM pack.
///
/// `path` is a filesystem-style path inside the pack (for example
/// `"fonts/dogica.uf"`). Returns `Error(Undefined)` when the resource is
/// missing (`undefined` from AtomVM).
///
/// See [`atomvm:read_priv/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#read-priv-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "read_priv")
pub fn read_priv(pack: String, path: String) -> Result(BitArray, Error)

/// Read a `priv/` resource, returning `None` when absent instead of an error.
pub fn read_priv_option(pack: String, path: String) -> Option(BitArray) {
  case read_priv(pack, path) {
    Ok(bytes) -> option.Some(bytes)
    Error(_) -> option.None
  }
}

/// Random 32-bit integer.
///
/// See [`atomvm:random/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#random-0).
@external(erlang, "atomvm", "random")
pub fn random() -> Int
