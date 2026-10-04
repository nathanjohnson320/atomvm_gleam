/// AtomVM platform helpers (`atomvm` module).
///
/// See [Module atomvm](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html).
///
/// Upstream source:
/// [atomvm.erl](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/atomvm.erl).
///
/// Note: AtomVM's `rand_bytes/1` is deprecated in favor of
/// `crypto:strong_rand_bytes/1`. Prefer a crypto wrapper when available; this
/// module does not wrap the deprecated API.
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

/// AtomVM platform moniker returned by [`platform`](#platform).
///
/// See [`atomvm:platform/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#platform-0).
pub type Platform {
  GenericUnix
  Emscripten
  Esp32
  Pico
  Stm32
}

/// Return the platform moniker for the running AtomVM build.
///
/// See [`atomvm:platform/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#platform-0).
@external(erlang, "atomvm", "platform")
pub fn platform() -> Platform

/// Mount an AVM pack file (or ESP32 partition path) under `name`.
///
/// On ESP32, `path` is typically `"/dev/partition/by-name/assets.avm"`.
/// `name` becomes the Erlang atom used with [`read_priv`](#read_priv).
///
/// See [`atomvm:add_avm_pack_file/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#add-avm-pack-file-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "add_avm_pack_file")
pub fn add_avm_pack_file(path: String, name: String) -> Result(Nil, Error)

/// Mount AVM pack data from a binary under `name`.
///
/// See [`atomvm:add_avm_pack_binary/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#add-avm-pack-binary-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "add_avm_pack_binary")
pub fn add_avm_pack_binary(avm_data: BitArray, name: String) -> Result(Nil, Error)

/// Close a previously mounted AVM pack referenced by `name`.
///
/// See [`atomvm:close_avm_pack/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#close-avm-pack-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "close_avm_pack")
pub fn close_avm_pack(name: String) -> Result(Nil, Error)

/// Return the start beam module name (with suffix) for a mounted AVM pack.
///
/// See [`atomvm:get_start_beam/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#get-start-beam-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "get_start_beam")
pub fn get_start_beam(avm: String) -> Result(BitArray, Error)

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
/// For random byte sequences, prefer `crypto:strong_rand_bytes/1` rather than
/// the deprecated AtomVM `rand_bytes/1` API.
///
/// See [`atomvm:random/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#random-0).
@external(erlang, "atomvm", "random")
pub fn random() -> Int

/// Clock identifier for [`posix_clock_settime`](#posix_clock_settime).
pub type ClockId {
  Realtime
}

/// Set the system clock (platforms with `clock_settime(2)`).
///
/// `value_since_unix_epoch` is `#(seconds, nanoseconds)`.
///
/// See [`atomvm:posix_clock_settime/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-clock-settime-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_clock_settime")
pub fn posix_clock_settime(
  clock_id: ClockId,
  value_since_unix_epoch: #(Int, Int),
) -> Result(Nil, Error)
