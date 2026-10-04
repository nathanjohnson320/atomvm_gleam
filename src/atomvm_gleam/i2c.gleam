//// Typed wrappers for AtomVM 0.7 `i2c`.
////
//// Upstream:
//// [libs/avm_esp32/src/i2c.erl](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl)
//// (same export names on RP2/STM32 under `avm_rp2` / `avm_stm32`).
////
//// ## Two write styles
////
//// **Register write** — `write_bytes/4` (and `read_bytes/4`) are one-shot
//// transactions: they address a device, send a register/pointer byte, then
//// write or read a payload. Do **not** wrap them in
//// `begin_transmission` / `end_transmission`.
////
//// **Transmission framing** — `begin_transmission` → `write_byte` /
//// `write_transmission_bytes` → `end_transmission` builds a multi-byte write
//// by hand (useful when the first byte is not a simple register pointer, or
//// when streaming several bytes in one stop-bit-framed message).
//// `write_bytes_to` is the one-shot address+payload write without a register
//// byte (upstream `i2c:write_bytes/3`); also not framed.

/// Opaque handle for an AtomVM I²C bus opened via `i2c:open/1`.
///
/// See [i2c.erl](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
pub type Bus

/// Errors from the AtomVM i2c driver.
///
/// See [i2c.erl](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// Bus open options. `clock_speed_hz` is required on AtomVM.
///
/// See [`i2c:open/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
pub type Config {
  Config(scl: Int, sda: Int, clock_speed_hz: Int)
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

/// Open an I²C bus.
///
/// See [`i2c:open/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
pub fn open(config: Config) -> Result(Bus, Error) {
  let Config(scl:, sda:, clock_speed_hz:) = config
  open_ffi(scl, sda, clock_speed_hz)
}

@external(erlang, "atomvm_gleam_i2c_ffi", "open")
fn open_ffi(scl: Int, sda: Int, clock_speed_hz: Int) -> Result(Bus, Error)

/// Close an I²C bus.
///
/// See [`i2c:close/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
@external(erlang, "atomvm_gleam_i2c_ffi", "close")
pub fn close(bus: Bus) -> Result(Nil, Error)

/// Begin a framed write to `address`.
///
/// Follow with one or more `write_byte` / `write_transmission_bytes` calls,
/// then `end_transmission`. Not used with register `write_bytes` / `read_bytes`.
///
/// See [`i2c:begin_transmission/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
@external(erlang, "atomvm_gleam_i2c_ffi", "begin_transmission")
pub fn begin_transmission(bus: Bus, address: Int) -> Result(Nil, Error)

/// Queue one byte inside an open transmission (`begin_transmission` …
/// `end_transmission`).
///
/// See [`i2c:write_byte/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
@external(erlang, "atomvm_gleam_i2c_ffi", "write_byte")
pub fn write_byte(bus: Bus, byte: Int) -> Result(Nil, Error)

/// Queue a byte sequence inside an open transmission.
///
/// Upstream `i2c:write_bytes/2`. Distinct Gleam name because Gleam cannot
/// overload `write_bytes/4`.
///
/// See [`i2c:write_bytes/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
@external(erlang, "atomvm_gleam_i2c_ffi", "write_transmission_bytes")
pub fn write_transmission_bytes(bus: Bus, data: BitArray) -> Result(Nil, Error)

/// End a framed write started with `begin_transmission`.
///
/// See [`i2c:end_transmission/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
@external(erlang, "atomvm_gleam_i2c_ffi", "end_transmission")
pub fn end_transmission(bus: Bus) -> Result(Nil, Error)

/// Read `count` bytes from `address` at `register` (pointer byte).
///
/// One-shot; do not wrap in `begin_transmission` / `end_transmission`.
///
/// See [`i2c:read_bytes/4`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
@external(erlang, "atomvm_gleam_i2c_ffi", "read_bytes")
pub fn read_bytes(
  bus: Bus,
  address: Int,
  register: Int,
  count: Int,
) -> Result(BitArray, Error)

/// Write `data` to `address` (no register pointer byte).
///
/// Upstream `i2c:write_bytes/3`. One-shot; do not wrap in transmission helpers.
/// Distinct Gleam name because Gleam cannot overload `write_bytes/4`.
///
/// See [`i2c:write_bytes/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
@external(erlang, "atomvm_gleam_i2c_ffi", "write_bytes_to")
pub fn write_bytes_to(
  bus: Bus,
  address: Int,
  data: BitArray,
) -> Result(Nil, Error)

/// Write `data` to `address` at `register` (pointer byte).
///
/// One-shot register write (upstream `i2c:write_bytes/4`). Do not wrap in
/// `begin_transmission` / `end_transmission`; use those helpers when you need
/// a custom framed payload instead.
///
/// See [`i2c:write_bytes/4`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/i2c.erl).
@external(erlang, "atomvm_gleam_i2c_ffi", "write_bytes")
pub fn write_bytes(
  bus: Bus,
  address: Int,
  register: Int,
  data: BitArray,
) -> Result(Nil, Error)
