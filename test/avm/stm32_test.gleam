//// STM32 suite — port GPIO with `{Bank, Pin}` (not ESP-style pin numbers).

import atomvm_gleam/gpio
import avm/check.{type Failure}
import avm/expect
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  use handle <- result.try(expect.must_ok_value(
    "gpio.start",
    gpio.start(),
    gpio.error_to_string,
  ))
  // PB7 — programmers guide example; BankPin encodes as Erlang `{b, 7}`.
  let pin = gpio.bank(gpio.B, 7)
  use _ <- result.try(expect.must_ok(
    "gpio.set_direction",
    gpio.set_direction(handle, pin, gpio.Output),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.set_level",
    gpio.set_level(handle, pin, gpio.PinHigh),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.read",
    gpio.read(handle, pin),
    gpio.error_to_string,
  ))
  expect.must_ok("gpio.close", gpio.close(handle), gpio.error_to_string)
}
