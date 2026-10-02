import gleam/option.{type Option}

/// Opaque handle for an AtomVM SPI bus opened via `spi:open/1`.
///
/// See [Module spi](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html).
pub type Spi

/// Errors from the AtomVM spi driver.
///
/// Known reason atoms are Gleam constructors (so `{error, badarg}` is
/// `Error(Badarg)`). Bare AtomVM `error` becomes `Failed`. Anything else
/// lands in `Other` as a string because AtomVM types reasons as open `term()`.
///
/// See [Module spi](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html).
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// SPI bus settings. Each field is one optional key of AtomVM `bus_config`.
/// `None` omits the key. `pico` is the newer name for MOSI, `poci` for MISO.
/// A present pin is the GPIO number; `-1` means that line is not wired, which
/// is how the SK6812 chain marks its missing clock.
///
/// See [bus_config()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html#bus-config).
pub type BusConfig {
  BusConfig(
    peripheral: Option(String),
    sclk: Option(Int),
    mosi: Option(Int),
    miso: Option(Int),
    pico: Option(Int),
    poci: Option(Int),
  )
}

/// Per-follower device settings. Maps to one entry in `device_config`.
/// `name` becomes the Erlang atom used with `read_at` / `write` / etc.
///
/// See [device_config()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html#device-config).
pub type DeviceConfig {
  DeviceConfig(
    name: String,
    cs: Int,
    clock_speed_hz: Option(Int),
    mode: Option(Int),
    address_len_bits: Option(Int),
    command_len_bits: Option(Int),
  )
}

/// Full `spi:open/1` parameters.
///
/// See [params()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html#params).
pub type Params {
  Params(bus_config: BusConfig, device_config: List(DeviceConfig))
}

/// SPI transaction map fields. All optional per the AtomVM docs.
///
/// See [transaction()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html#transaction).
pub type Transaction {
  Transaction(
    command: Option(Int),
    address: Option(Int),
    write_data: Option(BitArray),
    write_bits: Option(Int),
    read_bits: Option(Int),
  )
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

/// Open an SPI bus. Pass `device_config: []` when AtomGL owns the device
/// (as on the badge display).
///
/// See [`spi:open/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html#open-1).
pub fn open(params: Params) -> Result(Spi, Error) {
  let Params(bus_config:, device_config:) = params
  let BusConfig(peripheral:, sclk:, mosi:, miso:, pico:, poci:) = bus_config
  open_ffi(peripheral, sclk, mosi, miso, pico, poci, device_config)
}

@external(erlang, "atomvm_gleam_spi_ffi", "open")
fn open_ffi(
  peripheral: Option(String),
  sclk: Option(Int),
  mosi: Option(Int),
  miso: Option(Int),
  pico: Option(Int),
  poci: Option(Int),
  devices: List(DeviceConfig),
) -> Result(Spi, Error)

/// Close the SPI driver and free its resources.
///
/// See [`spi:close/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html#close-1).
@external(erlang, "atomvm_gleam_spi_ffi", "close")
pub fn close(spi: Spi) -> Result(Nil, Error)

/// Read a value from an address on a named device.
///
/// See [`spi:read_at/4`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html#read-at-4).
@external(erlang, "atomvm_gleam_spi_ffi", "read_at")
pub fn read_at(
  spi: Spi,
  device_name: String,
  address: Int,
  len: Int,
) -> Result(Int, Error)

/// Write a value to an address on a named device.
///
/// See [`spi:write_at/5`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html#write-at-5).
@external(erlang, "atomvm_gleam_spi_ffi", "write_at")
pub fn write_at(
  spi: Spi,
  device_name: String,
  address: Int,
  len: Int,
  data: Int,
) -> Result(Int, Error)

/// Write using a transaction map.
///
/// See [`spi:write/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html#write-3).
pub fn write(
  spi: Spi,
  device_name: String,
  transaction: Transaction,
) -> Result(Nil, Error) {
  write_ffi(spi, device_name, transaction)
}

@external(erlang, "atomvm_gleam_spi_ffi", "write")
fn write_ffi(
  spi: Spi,
  device_name: String,
  transaction: Transaction,
) -> Result(Nil, Error)

/// Write and simultaneously read using a transaction map.
///
/// See [`spi:write_read/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/spi.html#write-read-3).
pub fn write_read(
  spi: Spi,
  device_name: String,
  transaction: Transaction,
) -> Result(BitArray, Error) {
  write_read_ffi(spi, device_name, transaction)
}

@external(erlang, "atomvm_gleam_spi_ffi", "write_read")
fn write_read_ffi(
  spi: Spi,
  device_name: String,
  transaction: Transaction,
) -> Result(BitArray, Error)
