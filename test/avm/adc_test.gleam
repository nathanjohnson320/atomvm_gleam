//// ADC convenience API (start/read/stop); resource path lives in esp32_test.

import atomvm_gleam/adc
import atomvm_gleam/atomvm
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    _ -> adc_convenience()
  }
}

fn adc_convenience() -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_not_supported(
    "adc.start",
    adc.start(),
    fn(e) {
      case e {
        adc.NotSupported -> True
        adc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    adc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "adc.start_pin",
    adc.start_pin(36),
    fn(e) {
      case e {
        adc.NotSupported -> True
        adc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    adc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "adc.start_pin_with",
    adc.start_pin_with(36, adc.BitMax, adc.Db11),
    fn(e) {
      case e {
        adc.NotSupported -> True
        adc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    adc.error_to_string,
  ))
  use _ <- result.try(case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    True -> {
      use _ <- result.try(expect.ok_or_not_supported(
        "adc.read",
        adc.read(36),
        fn(e) {
          case e {
            adc.NotSupported -> True
            adc.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        adc.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "adc.read_with",
        adc.read_with(
          36,
          adc.SampleOptions(raw: True, voltage: True, samples: 4),
        ),
        fn(e) {
          case e {
            adc.NotSupported -> True
            adc.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        adc.error_to_string,
      ))
      Ok(Nil)
    }
    False -> {
      use _ <- result.try(integration.skip(
        "adc.read / read_with (QEMU hang; set AVM_GLEAM_INTEGRATION=1)",
      ))
      use _ <- result.try(check.cover_not_supported("adc.read"))
      use _ <- result.try(check.cover_not_supported("adc.read_with"))
      Ok(Nil)
    }
  })
  use _ <- result.try(expect.ok_or_not_supported(
    "adc.stop_pin",
    adc.stop_pin(36),
    fn(e) {
      case e {
        adc.NotSupported -> True
        adc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    adc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "adc.stop",
    adc.stop(),
    fn(e) {
      case e {
        adc.NotSupported -> True
        adc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    adc.error_to_string,
  ))
  Ok(Nil)
}
