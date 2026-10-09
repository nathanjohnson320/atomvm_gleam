//// ADC convenience API — ESP32 owns it. `start` / `stop` must Ok on ESP32;
//// `read` hangs under QEMU → SKIP unless INTEGRATION. Off-platform: NotSupported.

import atomvm_gleam/adc
import atomvm_gleam/atomvm
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    atomvm.Esp32 -> adc_esp32()
    _ -> adc_off_platform()
  }
}

fn adc_ns(e: adc.Error) -> Bool {
  case e {
    adc.NotSupported -> True
    adc.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
  }
}

fn adc_off_platform() -> Result(Nil, Failure) {
  expect.must_not_supported(
    "adc.start",
    adc.start(),
    adc_ns,
    adc.error_to_string,
  )
}

fn adc_esp32() -> Result(Nil, Failure) {
  use _ <- result.try(expect.must_ok(
    "adc.start",
    adc.start(),
    adc.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "adc.start_pin",
    adc.start_pin(36),
    adc.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "adc.start_pin_with",
    adc.start_pin_with(36, adc.BitMax, adc.Db11),
    adc.error_to_string,
  ))
  use _ <- result.try(case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    True -> {
      use _ <- result.try(expect.must_ok(
        "adc.read",
        adc.read(36),
        adc.error_to_string,
      ))
      use _ <- result.try(expect.must_ok(
        "adc.read_with",
        adc.read_with(
          36,
          adc.SampleOptions(raw: True, voltage: True, samples: 4),
        ),
        adc.error_to_string,
      ))
      Ok(Nil)
    }
    False ->
      integration.skip(
        "adc.read / read_with (QEMU hang; set AVM_GLEAM_INTEGRATION=1)",
      )
  })
  use _ <- result.try(expect.must_ok(
    "adc.stop_pin",
    adc.stop_pin(36),
    adc.error_to_string,
  ))
  expect.must_ok("adc.stop", adc.stop(), adc.error_to_string)
}
