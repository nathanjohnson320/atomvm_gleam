//// UART - owned on ESP32, Pico, STM32, and unix (loopback suite).
////
//// ESP QEMU open can hang/WDT - SKIP unless INTEGRATION.
//// Pico / STM32: open/write/close must Ok; short read may Timeout/Failed.
//// Unix loopback is `uart_loopback_test`. Emscripten: no-op.

import atomvm_gleam/atomvm
import atomvm_gleam/uart
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/option
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Esp32 -> uart_esp32()
    atomvm.Pico | atomvm.Stm32 -> uart_mcu_live()
    atomvm.GenericUnix | atomvm.Emscripten -> check.ok()
  }
}

fn uart_read_runtime(e: uart.Error) -> Bool {
  case e {
    uart.NotSupported -> False
    _ -> True
  }
}

fn uart_esp32() -> Result(Nil, Failure) {
  case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False ->
      integration.skip(
        "uart open (QEMU hang/badarg; set AVM_GLEAM_INTEGRATION=1)",
      )
    True -> uart_esp32_live()
  }
}

fn uart_esp32_live() -> Result(Nil, Failure) {
  use u <- result.try(expect.must_ok_value(
    "uart.open_default",
    uart.open_default(uart.default_config()),
    uart.error_to_string,
  ))
  uart_rw_close(u)
}

fn uart_mcu_live() -> Result(Nil, Failure) {
  // RP2 / STM32 require tx+rx pins (ESP open_default does not).
  // Prefer UART1 + GP4/GP5 so we do not collide with console UART0 on 0/1.
  let #(name, tx, rx) = case atomvm.platform() {
    atomvm.Pico -> #("UART1", 4, 5)
    _ -> #("UART0", 0, 1)
  }
  let cfg =
    uart.Config(
      ..uart.default_config(),
      tx: option.Some(tx),
      rx: option.Some(rx),
    )
  use u <- result.try(expect.must_ok_value(
    "uart.open",
    uart.open(name, cfg),
    uart.error_to_string,
  ))
  uart_rw_close(u)
}

fn uart_rw_close(u: uart.Uart) -> Result(Nil, Failure) {
  use _ <- result.try(expect.must_ok(
    "uart.write",
    uart.write(u, <<"x">>),
    uart.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "uart.read",
    uart.read(u, 10),
    uart_read_runtime,
    uart.error_to_string,
  ))
  expect.must_ok("uart.close", uart.close(u), uart.error_to_string)
}
