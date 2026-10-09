//// SPI — owned on ESP32, Pico (RP2), and STM32 (AtomVM 0.7).
////
//// ESP open hangs under QEMU → SKIP unless `AVM_GLEAM_INTEGRATION=1`.
//// Pico / STM32 / live ESP: `open`/`close` must Ok. Unix / WASM: NotSupported.

import atomvm_gleam/atomvm
import atomvm_gleam/spi
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/option
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    atomvm.Esp32 -> spi_esp32()
    atomvm.Pico | atomvm.Stm32 -> spi_live()
    atomvm.GenericUnix -> spi_off_platform()
  }
}

fn spi_ns(e: spi.Error) -> Bool {
  case e {
    spi.NotSupported -> True
    spi.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
  }
}

fn params() -> spi.Params {
  case atomvm.platform() {
    atomvm.Esp32 ->
      spi.Params(
        bus_config: spi.BusConfig(
          peripheral: option.Some("HSPI"),
          sclk: option.Some(14),
          mosi: option.Some(13),
          miso: option.Some(12),
          pico: option.None,
          poci: option.None,
        ),
        device_config: [],
      )
    // RP2 peripheral 0|1; STM32 1..6 — digits-only string → int in FFI.
    atomvm.Pico ->
      spi.Params(
        bus_config: spi.BusConfig(
          peripheral: option.Some("0"),
          sclk: option.Some(18),
          mosi: option.Some(19),
          miso: option.Some(16),
          pico: option.None,
          poci: option.None,
        ),
        device_config: [],
      )
    atomvm.Stm32 ->
      spi.Params(
        bus_config: spi.BusConfig(
          peripheral: option.Some("1"),
          sclk: option.Some(5),
          mosi: option.Some(7),
          miso: option.Some(6),
          pico: option.None,
          poci: option.None,
        ),
        device_config: [],
      )
    _ ->
      spi.Params(
        bus_config: spi.BusConfig(
          peripheral: option.None,
          sclk: option.Some(14),
          mosi: option.Some(13),
          miso: option.Some(12),
          pico: option.None,
          poci: option.None,
        ),
        device_config: [],
      )
  }
}

fn spi_off_platform() -> Result(Nil, Failure) {
  expect.must_not_supported(
    "spi.open",
    spi.open(params()),
    spi_ns,
    spi.error_to_string,
  )
}

fn spi_esp32() -> Result(Nil, Failure) {
  case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False ->
      integration.skip("spi.open (QEMU hang/WDT; set AVM_GLEAM_INTEGRATION=1)")
    True -> spi_live()
  }
}

fn spi_live() -> Result(Nil, Failure) {
  use s <- result.try(expect.must_ok_value(
    "spi.open",
    spi.open(params()),
    spi.error_to_string,
  ))
  expect.must_ok("spi.close", spi.close(s), spi.error_to_string)
}
