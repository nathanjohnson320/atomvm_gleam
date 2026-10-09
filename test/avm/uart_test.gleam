//// UART open_default smoke on ESP32 (loopback suite covers GenericUnix).

import atomvm_gleam/atomvm
import atomvm_gleam/uart
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  // uart open can crash / WDT under QEMU, or return badarg when the
  // driver rejects the default name. Only exercise opens on INTEGRATION.
  case atomvm.platform() {
    atomvm.Esp32 ->
      case integration.env_flag("AVM_GLEAM_INTEGRATION") {
        False -> {
          use _ <- result.try(integration.skip(
            "uart open (QEMU hang/badarg; set AVM_GLEAM_INTEGRATION=1)",
          ))
          use _ <- result.try(check.cover_not_supported("uart.open_default"))
          use _ <- result.try(check.cover_not_supported("uart.write"))
          use _ <- result.try(check.cover_not_supported("uart.read"))
          Ok(Nil)
        }
        True -> uart_esp32_live()
      }
    _ -> check.ok()
  }
}

fn uart_esp32_live() -> Result(Nil, Failure) {
  use u_r <- result.try(expect.ok_value_or_not_supported(
    "uart.open_default",
    uart.open_default(uart.default_config()),
    fn(e) {
      case e {
        uart.NotSupported | uart.Badarg | uart.Failed -> True
        uart.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    uart.error_to_string,
  ))
  case u_r {
    Error(Nil) -> {
      use _ <- result.try(check.cover_not_supported("uart.write"))
      use _ <- result.try(check.cover_not_supported("uart.read"))
      Ok(Nil)
    }
    Ok(u) -> {
      use _ <- result.try(expect.ok_or_not_supported(
        "uart.write",
        uart.write(u, <<"x">>),
        fn(e) {
          case e {
            uart.NotSupported -> True
            uart.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        uart.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "uart.read",
        uart.read(u, 10),
        fn(e) {
          case e {
            uart.NotSupported -> True
            uart.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        uart.error_to_string,
      ))
      use _ <- result.try(check.cover_ok("uart.close", uart.close(u)))
      Ok(Nil)
    }
  }
}
