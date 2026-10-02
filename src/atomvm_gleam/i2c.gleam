/// Opaque handle for an AtomVM I²C bus opened via `i2c:open/1`.
///
/// See [Module i2c](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/i2c.html).
pub type Bus

/// Errors from the AtomVM i2c driver.
///
/// See [Module i2c](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/i2c.html).
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// Bus open options. `clock_speed_hz` is required on AtomVM.
///
/// See [`i2c:open/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/i2c.html#open-1).
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
/// See [`i2c:open/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/i2c.html#open-1).
pub fn open(config: Config) -> Result(Bus, Error) {
  let Config(scl:, sda:, clock_speed_hz:) = config
  open_ffi(scl, sda, clock_speed_hz)
}

@external(erlang, "atomvm_gleam_i2c_ffi", "open")
fn open_ffi(scl: Int, sda: Int, clock_speed_hz: Int) -> Result(Bus, Error)

/// Close an I²C bus.
///
/// See [`i2c:close/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/i2c.html#close-1).
@external(erlang, "atomvm_gleam_i2c_ffi", "close")
pub fn close(bus: Bus) -> Result(Nil, Error)

/// Read `count` bytes from `address` at `register` (pointer byte).
///
/// See [`i2c:read_bytes/4`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/i2c.html#read-bytes-4).
@external(erlang, "atomvm_gleam_i2c_ffi", "read_bytes")
pub fn read_bytes(
  bus: Bus,
  address: Int,
  register: Int,
  count: Int,
) -> Result(BitArray, Error)

/// Write `data` to `address` at `register` (pointer byte).
///
/// See [`i2c:write_bytes/4`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/i2c.html#write-bytes-4).
@external(erlang, "atomvm_gleam_i2c_ffi", "write_bytes")
pub fn write_bytes(
  bus: Bus,
  address: Int,
  register: Int,
  data: BitArray,
) -> Result(Nil, Error)
