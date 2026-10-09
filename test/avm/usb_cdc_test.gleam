//// USB CDC smoke on ESP32 (INTEGRATION for live open).

import atomvm_gleam/atomvm
import atomvm_gleam/usb_cdc
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  // usb_cdc open can crash / WDT under QEMU. Only exercise opens on INTEGRATION.
  case atomvm.platform() {
    atomvm.Esp32 ->
      case integration.env_flag("AVM_GLEAM_INTEGRATION") {
        False -> {
          use _ <- result.try(integration.skip(
            "usb_cdc open (QEMU hang/badarg; set AVM_GLEAM_INTEGRATION=1)",
          ))
          use _ <- result.try(check.cover_not_supported("usb_cdc.open_default"))
          use _ <- result.try(check.cover_not_supported("usb_cdc.open"))
          use _ <- result.try(check.cover_not_supported("usb_cdc.write"))
          use _ <- result.try(check.cover_not_supported("usb_cdc.read"))
          use _ <- result.try(check.cover_not_supported("usb_cdc.read_blocking"))
          use _ <- result.try(check.cover_not_supported("usb_cdc.close"))
          Ok(Nil)
        }
        True -> usb_cdc_esp32_live()
      }
    _ -> check.ok()
  }
}

fn usb_cdc_esp32_live() -> Result(Nil, Failure) {
  use c_r <- result.try(expect.ok_value_or_not_supported(
    "usb_cdc.open_default",
    usb_cdc.open_default(usb_cdc.default_config()),
    fn(e) {
      case e {
        usb_cdc.NotSupported -> True
        usb_cdc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    usb_cdc.error_to_string,
  ))
  case c_r {
    Error(Nil) -> {
      use _ <- result.try(check.cover_not_supported("usb_cdc.open"))
      use _ <- result.try(check.cover_not_supported("usb_cdc.write"))
      use _ <- result.try(check.cover_not_supported("usb_cdc.read"))
      use _ <- result.try(check.cover_not_supported("usb_cdc.read_blocking"))
      use _ <- result.try(check.cover_not_supported("usb_cdc.close"))
      Ok(Nil)
    }
    Ok(c) -> {
      use _ <- result.try(check.cover("usb_cdc.open", check.ok()))
      use _ <- result.try(expect.ok_or_not_supported(
        "usb_cdc.write",
        usb_cdc.write(c, <<"x">>),
        fn(e) {
          case e {
            usb_cdc.NotSupported -> True
            usb_cdc.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        usb_cdc.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "usb_cdc.read",
        usb_cdc.read(c, 10),
        fn(e) {
          case e {
            usb_cdc.NotSupported -> True
            usb_cdc.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        usb_cdc.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "usb_cdc.read_blocking",
        usb_cdc.read_blocking(c),
        fn(e) {
          case e {
            usb_cdc.NotSupported -> True
            usb_cdc.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        usb_cdc.error_to_string,
      ))
      check.cover_ok("usb_cdc.close", usb_cdc.close(c))
    }
  }
}
