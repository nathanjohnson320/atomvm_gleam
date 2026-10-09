//// USB CDC — owned on ESP32 / Pico / STM32 (AtomVM 0.7). Open can hang under
//// QEMU / rp2040js — SKIP unless INTEGRATION (emu cannot prove ownership).
//// Live: open_default/write/close must Ok; short reads may fail.

import atomvm_gleam/atomvm
import atomvm_gleam/usb_cdc
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Esp32 | atomvm.Pico | atomvm.Stm32 -> usb_cdc_mcu()
    // Missing `usb_cdc` beam aborts (undef) rather than returning NotSupported
    // from the current FFI — do not call off MCU.
    _ -> check.ok()
  }
}

fn usb_cdc_read_runtime(e: usb_cdc.Error) -> Bool {
  case e {
    usb_cdc.NotSupported -> False
    _ -> True
  }
}

fn usb_cdc_mcu() -> Result(Nil, Failure) {
  case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False ->
      integration.skip(
        "usb_cdc open (QEMU hang/badarg; set AVM_GLEAM_INTEGRATION=1)",
      )
    True -> usb_cdc_live()
  }
}

fn usb_cdc_live() -> Result(Nil, Failure) {
  use c <- result.try(expect.must_ok_value(
    "usb_cdc.open_default",
    usb_cdc.open_default(usb_cdc.default_config()),
    usb_cdc.error_to_string,
  ))
  use _ <- result.try(check.cover("usb_cdc.open", check.ok()))
  use _ <- result.try(expect.must_ok(
    "usb_cdc.write",
    usb_cdc.write(c, <<"x">>),
    usb_cdc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "usb_cdc.read",
    usb_cdc.read(c, 10),
    usb_cdc_read_runtime,
    usb_cdc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "usb_cdc.read_blocking",
    usb_cdc.read_blocking(c),
    usb_cdc_read_runtime,
    usb_cdc.error_to_string,
  ))
  expect.must_ok("usb_cdc.close", usb_cdc.close(c), usb_cdc.error_to_string)
}
