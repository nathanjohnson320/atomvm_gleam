//// STM32 suite.

import atomvm_gleam/gpio
import avm/check.{type Failure}
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  use handle <- result.try(check.assert_ok("gpio.start", gpio.start()))
  use _ <- result.try(check.assert_ok(
    "gpio.set_direction",
    gpio.set_direction(handle, gpio.pin(0), gpio.Output),
  ))
  use _ <- result.try(check.assert_ok("gpio.close", gpio.close(handle)))
  Ok(Nil)
}
