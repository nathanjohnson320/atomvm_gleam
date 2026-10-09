//// I2C - owned on ESP32, Pico (RP2), and STM32 (AtomVM 0.7).
////
//// ESP open hangs under QEMU → SKIP unless `AVM_GLEAM_INTEGRATION=1`.
//// Pico / STM32 / live ESP: `open`/`close` must Ok; transfers may
//// Failed/Timeout/Badarg with no slave. Unix / WASM: not owned.

import atomvm_gleam/atomvm
import atomvm_gleam/i2c
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    atomvm.Esp32 -> i2c_esp32()
    atomvm.Pico | atomvm.Stm32 -> i2c_live()
    atomvm.GenericUnix -> i2c_off_platform()
  }
}

fn i2c_ns(e: i2c.Error) -> Bool {
  case e {
    i2c.NotSupported -> True
    i2c.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
  }
}

fn i2c_xfer_runtime(e: i2c.Error) -> Bool {
  case e {
    i2c.NotSupported -> False
    _ -> True
  }
}

fn i2c_off_platform() -> Result(Nil, Failure) {
  expect.must_not_supported(
    "i2c.open",
    i2c.open(i2c.Config(scl: 22, sda: 21, clock_speed_hz: 100_000)),
    i2c_ns,
    i2c.error_to_string,
  )
}

fn i2c_esp32() -> Result(Nil, Failure) {
  case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False ->
      integration.skip("i2c.open (QEMU hang/WDT; set AVM_GLEAM_INTEGRATION=1)")
    True -> i2c_live()
  }
}

fn i2c_live() -> Result(Nil, Failure) {
  use bus <- result.try(expect.must_ok_value(
    "i2c.open",
    i2c.open(i2c.Config(scl: 22, sda: 21, clock_speed_hz: 100_000)),
    i2c.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "i2c.begin_transmission",
    i2c.begin_transmission(bus, 0x50),
    i2c_xfer_runtime,
    i2c.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "i2c.write_byte",
    i2c.write_byte(bus, 0),
    i2c_xfer_runtime,
    i2c.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "i2c.write_transmission_bytes",
    i2c.write_transmission_bytes(bus, <<0>>),
    i2c_xfer_runtime,
    i2c.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "i2c.end_transmission",
    i2c.end_transmission(bus),
    i2c_xfer_runtime,
    i2c.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "i2c.read_bytes",
    i2c.read_bytes(bus, 0x50, 0, 1),
    i2c_xfer_runtime,
    i2c.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "i2c.write_bytes_to",
    i2c.write_bytes_to(bus, 0x50, <<0>>),
    i2c_xfer_runtime,
    i2c.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "i2c.write_bytes",
    i2c.write_bytes(bus, 0x50, 0, <<0>>),
    i2c_xfer_runtime,
    i2c.error_to_string,
  ))
  expect.must_ok("i2c.close", i2c.close(bus), i2c.error_to_string)
}
