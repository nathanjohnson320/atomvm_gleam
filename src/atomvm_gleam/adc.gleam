//// Analog to digital conversion on the ESP32 family.
////
//// [Module esp_adc](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html)
//// has two APIs, and an application uses one of them. `init`, `acquire`, and
//// `sample` take resource handles. `start_pin`, `read`, and `stop` go through
//// a gen_server that owns those handles itself.

import gleam/erlang/atom.{type Atom}
import gleam/erlang/process.{type Pid}
import gleam/option.{type Option}
import gleam/result

/// Opaque ADC unit handle from `init`.
///
/// See [adc_rsrc()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#adc_rsrc).
pub type Unit

/// Opaque ADC channel handle from `acquire`.
///
/// See [adc_rsrc()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#adc_rsrc).
pub type Channel

/// Errors from the AtomVM ADC driver.
///
/// Known reason atoms are Gleam constructors (so `{error, timeout}` is
/// `Error(Timeout)`). Bare AtomVM `error` becomes `Failed`. Anything else
/// lands in `Other` as a string because AtomVM types reasons as open `term()`.
///
/// See [Module esp_adc](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html).
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// Sample resolution. `BitMax` selects the widest width the chip supports.
///
/// See [bit_width()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#bit_width).
pub type BitWidth {
  Bit9
  Bit10
  Bit11
  Bit12
  Bit13
  BitMax
}

/// Input attenuation. `Db12` reads the full 3.3 V window. `Db11` is the
/// default used by `acquire_default` and `start_pin`. `Db2Point5` is the
/// Erlang atom `db_2_5`.
///
/// See [attenuation()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#attenuation).
pub type Attenuation {
  Db0
  Db2Point5
  Db6
  Db11
  Db12
}

/// One ADC reading. `None` means that field was not requested (`undefined`
/// from AtomVM).
///
/// See [reading()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#reading).
pub type Reading {
  Reading(raw: Option(Int), millivolts: Option(Int))
}

/// What `sample_with` and `read_with` ask the driver to return.
///
/// `raw` and `voltage` select the fields of `Reading`. `samples` is how many
/// conversions to average. The short arities (`sample`, `read`) use both
/// fields and 64 samples.
///
/// See [read_option()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#read_option).
pub type SampleOptions {
  SampleOptions(raw: Bool, voltage: Bool, samples: Int)
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

/// Initialize the ADC unit. The returned handle is required by `acquire` and
/// `sample`.
///
/// This is a resource function. It cannot be used in an application that
/// calls `start`, `start_pin`, `read`, or `stop`.
///
/// See [`esp_adc:init/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#init-0).
@external(erlang, "atomvm_gleam_adc_ffi", "init")
pub fn init() -> Result(Unit, Error)

/// Release the ADC unit from `init`. Release each channel first.
///
/// This is a resource function. It cannot be used in an application that
/// calls `start`, `start_pin`, `read`, or `stop`.
///
/// See [`esp_adc:deinit/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#deinit-1).
@external(erlang, "atomvm_gleam_adc_ffi", "deinit")
pub fn deinit(unit: Unit) -> Result(Nil, Error)

/// Configure `pin` and return a channel handle.
///
/// This is a resource function. It cannot be used in an application that
/// calls `start`, `start_pin`, `read`, or `stop`.
///
/// See [`esp_adc:acquire/4`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#acquire-4).
pub fn acquire(
  pin: Int,
  unit: Unit,
  bit_width: BitWidth,
  attenuation: Attenuation,
) -> Result(Channel, Error) {
  acquire_ffi(
    pin,
    unit,
    bit_width_atom(bit_width),
    attenuation_atom(attenuation),
  )
}

@external(erlang, "atomvm_gleam_adc_ffi", "acquire")
fn acquire_ffi(
  pin: Int,
  unit: Unit,
  bit_width: Atom,
  attenuation: Atom,
) -> Result(Channel, Error)

/// Configure `pin` at `BitMax` and `Db11`.
///
/// This is a resource function. It cannot be used in an application that
/// calls `start`, `start_pin`, `read`, or `stop`.
///
/// See [`esp_adc:acquire/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#acquire-2).
@external(erlang, "atomvm_gleam_adc_ffi", "acquire_default")
pub fn acquire_default(pin: Int, unit: Unit) -> Result(Channel, Error)

/// Release a channel from `acquire`.
///
/// This is a resource function. It cannot be used in an application that
/// calls `start`, `start_pin`, `read`, or `stop`.
///
/// See [`esp_adc:release_channel/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#release_channel-1).
@external(erlang, "atomvm_gleam_adc_ffi", "release_channel")
pub fn release_channel(channel: Channel) -> Result(Nil, Error)

/// Read a channel. Returns the raw count and pin millivolts, averaged over
/// 64 samples.
///
/// This is a resource function. It cannot be used in an application that
/// calls `start`, `start_pin`, `read`, or `stop`.
///
/// See [`esp_adc:sample/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#sample-2).
pub fn sample(channel: Channel, unit: Unit) -> Result(Reading, Error) {
  result.map(sample_ffi(channel, unit), to_reading)
}

@external(erlang, "atomvm_gleam_adc_ffi", "sample")
fn sample_ffi(
  channel: Channel,
  unit: Unit,
) -> Result(#(Option(Int), Option(Int)), Error)

/// Read a channel with explicit fields and sample count.
///
/// This is a resource function. It cannot be used in an application that
/// calls `start`, `start_pin`, `read`, or `stop`.
///
/// See [`esp_adc:sample/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#sample-3).
pub fn sample_with(
  channel: Channel,
  unit: Unit,
  options: SampleOptions,
) -> Result(Reading, Error) {
  let SampleOptions(raw:, voltage:, samples:) = options
  result.map(sample_with_ffi(channel, unit, raw, voltage, samples), to_reading)
}

@external(erlang, "atomvm_gleam_adc_ffi", "sample_with")
fn sample_with_ffi(
  channel: Channel,
  unit: Unit,
  raw: Bool,
  voltage: Bool,
  samples: Int,
) -> Result(#(Option(Int), Option(Int)), Error)

/// Start the gen_server ADC driver without configuring a pin. The process is
/// registered as `adc_driver`.
///
/// This is a convenience function. It cannot be used in an application that
/// calls `init`, `acquire`, or `sample`.
///
/// See [`esp_adc:start/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#start-0).
@external(erlang, "atomvm_gleam_adc_ffi", "start")
pub fn start() -> Result(Pid, Error)

/// Configure `pin` on the gen_server driver at `BitMax` and `Db11`.
///
/// This is a convenience function. It cannot be used in an application that
/// calls `init`, `acquire`, or `sample`.
///
/// See [`esp_adc:start/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#start-1).
@external(erlang, "atomvm_gleam_adc_ffi", "start_pin")
pub fn start_pin(pin: Int) -> Result(Nil, Error)

/// Configure `pin` on the gen_server driver with the given resolution and
/// attenuation.
///
/// This is a convenience function. It cannot be used in an application that
/// calls `init`, `acquire`, or `sample`.
///
/// See [`esp_adc:start/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#start-2).
pub fn start_pin_with(
  pin: Int,
  bit_width: BitWidth,
  attenuation: Attenuation,
) -> Result(Nil, Error) {
  start_pin_with_ffi(
    pin,
    bit_width_atom(bit_width),
    attenuation_atom(attenuation),
  )
}

@external(erlang, "atomvm_gleam_adc_ffi", "start_pin_with")
fn start_pin_with_ffi(
  pin: Int,
  bit_width: Atom,
  attenuation: Atom,
) -> Result(Nil, Error)

/// Read a pin previously configured with `start_pin`. Returns the raw count
/// and pin millivolts, averaged over 64 samples.
///
/// This is a convenience function. It cannot be used in an application that
/// calls `init`, `acquire`, or `sample`.
///
/// See [`esp_adc:read/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#read-1).
pub fn read(pin: Int) -> Result(Reading, Error) {
  result.map(read_ffi(pin), to_reading)
}

@external(erlang, "atomvm_gleam_adc_ffi", "read")
fn read_ffi(pin: Int) -> Result(#(Option(Int), Option(Int)), Error)

/// Read a pin previously configured with `start_pin`, with explicit fields
/// and sample count.
///
/// This is a convenience function. It cannot be used in an application that
/// calls `init`, `acquire`, or `sample`.
///
/// See [`esp_adc:read/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#read-2).
pub fn read_with(pin: Int, options: SampleOptions) -> Result(Reading, Error) {
  let SampleOptions(raw:, voltage:, samples:) = options
  result.map(read_with_ffi(pin, raw, voltage, samples), to_reading)
}

@external(erlang, "atomvm_gleam_adc_ffi", "read_with")
fn read_with_ffi(
  pin: Int,
  raw: Bool,
  voltage: Bool,
  samples: Int,
) -> Result(#(Option(Int), Option(Int)), Error)

/// Release one pin from the gen_server driver.
///
/// This is a convenience function. It cannot be used in an application that
/// calls `init`, `acquire`, or `sample`.
///
/// See [`esp_adc:stop/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#stop-1).
@external(erlang, "atomvm_gleam_adc_ffi", "stop_pin")
pub fn stop_pin(pin: Int) -> Result(Nil, Error)

/// Stop the gen_server driver and release every pin.
///
/// This is a convenience function. It cannot be used in an application that
/// calls `init`, `acquire`, or `sample`.
///
/// See [`esp_adc:stop/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp_adc.html#stop-0).
@external(erlang, "atomvm_gleam_adc_ffi", "stop")
pub fn stop() -> Result(Nil, Error)

fn to_reading(pair: #(Option(Int), Option(Int))) -> Reading {
  let #(raw, millivolts) = pair
  Reading(raw:, millivolts:)
}

fn bit_width_atom(width: BitWidth) -> Atom {
  case width {
    Bit9 -> atom.create("bit_9")
    Bit10 -> atom.create("bit_10")
    Bit11 -> atom.create("bit_11")
    Bit12 -> atom.create("bit_12")
    Bit13 -> atom.create("bit_13")
    BitMax -> atom.create("bit_max")
  }
}

fn attenuation_atom(attenuation: Attenuation) -> Atom {
  case attenuation {
    Db0 -> atom.create("db_0")
    Db2Point5 -> atom.create("db_2_5")
    Db6 -> atom.create("db_6")
    Db11 -> atom.create("db_11")
    Db12 -> atom.create("db_12")
  }
}
