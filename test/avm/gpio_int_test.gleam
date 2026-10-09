//// GPIO interrupt path - set_int → trigger → `{gpio_interrupt, Pin}`.
////
//// ESP32 only (unix sysfs GPIO has no interrupt port). With
//// `AVM_GLEAM_GPIO_OUT` / `AVM_GLEAM_GPIO_IN` wired, asserts a Rising edge
//// message. Without a peer, only arms/disarms Rising (no level-high - that
//// floods IRQs under QEMU). Missing message → `SKIP` unless
//// `AVM_GLEAM_INTEGRATION=1`.

import atomvm_gleam/gpio
import avm/check.{type Failure, Failure}
import avm/integration
import gleam/erlang/process
import gleam/int
import gleam/option
import gleam/result

const default_pin = 18

fn fail(message: String) -> Result(a, Failure) {
  Error(Failure(message))
}

pub fn run() -> Result(Nil, Failure) {
  case gpio.start() {
    Error(gpio.NotSupported) -> integration.skip("gpio.start NotSupported")
    Error(reason) -> fail("gpio.start: " <> gpio.error_to_string(reason))
    Ok(g) -> {
      use _ <- result.try(check.cover("gpio.start", check.ok()))
      let outcome = case pin_pair() {
        option.Some(#(out_n, in_n)) -> edge_pair(g, out_n, in_n)
        option.None -> arm_disarm_only(g, default_pin)
      }
      let _ = gpio.remove_int(g, gpio.pin(default_pin))
      case pin_pair() {
        option.Some(#(_out_n, in_n)) -> {
          let _ = gpio.remove_int(g, gpio.pin(in_n))
          Nil
        }
        option.None -> Nil
      }
      let _ = gpio.close(g)
      let _ = gpio.stop()
      outcome
    }
  }
}

fn pin_pair() -> option.Option(#(Int, Int)) {
  case
    integration.env("AVM_GLEAM_GPIO_OUT"),
    integration.env("AVM_GLEAM_GPIO_IN")
  {
    option.Some(out_s), option.Some(in_s) ->
      case int.parse(out_s), int.parse(in_s) {
        Ok(out_n), Ok(in_n) -> option.Some(#(out_n, in_n))
        _, _ -> option.None
      }
    _, _ -> option.None
  }
}

fn edge_pair(g: gpio.Gpio, out_n: Int, in_n: Int) -> Result(Nil, Failure) {
  let out_pin = gpio.pin(out_n)
  let in_pin = gpio.pin(in_n)
  use _ <- result.try(check.cover_ok(
    "gpio.set_direction",
    gpio.set_direction(g, out_pin, gpio.Output),
  ))
  use _ <- result.try(check.cover_ok(
    "gpio.set_level",
    gpio.set_level(g, out_pin, gpio.PinLow),
  ))
  integration.sleep_ms(20)
  use _ <- result.try(check.cover_ok(
    "gpio.set_int_to",
    gpio.set_int_to(g, in_pin, gpio.Rising, process.self()),
  ))
  use _ <- result.try(check.cover_ok(
    "gpio.set_level",
    gpio.set_level(g, out_pin, gpio.PinHigh),
  ))
  use _ <- result.try(await_interrupt(in_n, 1000))
  use _ <- result.try(check.cover_ok(
    "gpio.remove_int",
    gpio.remove_int(g, in_pin),
  ))
  Ok(Nil)
}

/// No peer: cover set_int / remove_int only. Do not use level triggers.
fn arm_disarm_only(g: gpio.Gpio, pin_n: Int) -> Result(Nil, Failure) {
  let pin = gpio.pin(pin_n)
  use _ <- result.try(check.cover_ok(
    "gpio.set_int",
    gpio.set_int(g, pin, gpio.Rising),
  ))
  integration.sleep_ms(20)
  use _ <- result.try(check.cover_ok("gpio.remove_int", gpio.remove_int(g, pin)))
  case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    True ->
      fail(
        "gpio interrupt message requires AVM_GLEAM_GPIO_OUT/IN (AVM_GLEAM_INTEGRATION=1)",
      )
    False ->
      integration.skip(
        "gpio interrupt message needs AVM_GLEAM_GPIO_OUT/IN peer",
      )
  }
}

fn await_interrupt(pin_n: Int, timeout_ms: Int) -> Result(Nil, Failure) {
  case receive_gpio_interrupt(pin_n, timeout_ms) {
    Ok(_) -> check.ok()
    Error(_) ->
      case integration.env_flag("AVM_GLEAM_INTEGRATION") {
        True ->
          fail(
            "gpio interrupt not received on pin "
            <> int.to_string(pin_n)
            <> " (AVM_GLEAM_INTEGRATION=1)",
          )
        False ->
          integration.skip(
            "gpio interrupt not delivered; check AVM_GLEAM_GPIO_OUT/IN wiring",
          )
      }
  }
}

@external(erlang, "avm_test_env_ffi", "receive_gpio_interrupt")
fn receive_gpio_interrupt(pin: Int, timeout_ms: Int) -> Result(Int, String)
