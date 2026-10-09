//// Pico / RP2 suite — hard gpio + rtc; CYW43 NotSupported on non-W emu.

import atomvm_gleam/gpio
import atomvm_gleam/pico
import avm/check.{type Failure}
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  use _ <- result.try(gpio_smoke())
  use _ <- result.try(cyw43_expect())
  use _ <- result.try(rtc_expect())
  Ok(Nil)
}

fn gpio_smoke() -> Result(Nil, Failure) {
  let pin = gpio.pin(25)
  use _ <- result.try(check.cover_ok(
    "gpio.set_pin_mode",
    gpio.set_pin_mode(pin, gpio.Output),
  ))
  use _ <- result.try(check.cover_ok(
    "gpio.digital_write",
    gpio.digital_write(pin, gpio.PinHigh),
  ))
  use _ <- result.try(check.cover_ok(
    "gpio.digital_write",
    gpio.digital_write(pin, gpio.PinLow),
  ))
  use _ <- result.try(check.cover_ok(
    "gpio.set_function",
    gpio.set_function(25, gpio.Sio),
  ))
  Ok(Nil)
}

fn cyw43_expect() -> Result(Nil, Failure) {
  case pico.cyw43_arch_gpio_get(0) {
    Ok(level) -> {
      use _ <- result.try(check.cover("pico.cyw43_arch_gpio_get", check.ok()))
      use _ <- result.try(check.assert_true(
        "cyw43 level 0/1",
        level == 0 || level == 1,
      ))
      use _ <- result.try(check.cover_ok(
        "pico.cyw43_arch_gpio_put",
        pico.cyw43_arch_gpio_put(0, case level {
          0 -> pico.PinLow
          _ -> pico.PinHigh
        }),
      ))
      Ok(Nil)
    }
    Error(pico.NotSupported) -> {
      use _ <- result.try(check.cover_not_supported("pico.cyw43_arch_gpio_get"))
      use _ <- result.try(check.cover_not_supported("pico.cyw43_arch_gpio_put"))
      Ok(Nil)
    }
    Error(other) ->
      check.fail("cyw43 unexpected: " <> pico.error_to_string(other))
  }
}

fn rtc_expect() -> Result(Nil, Failure) {
  let datetime =
    pico.DateTime(
      date: pico.Date(year: 2026, month: 10, day: 9),
      time: pico.TimeOfDay(hour: 12, minute: 0, second: 0),
    )
  case pico.rtc_set_datetime(datetime) {
    Ok(Nil) -> check.cover("pico.rtc_set_datetime", check.ok())
    Error(pico.NotSupported) ->
      check.cover_not_supported("pico.rtc_set_datetime")
    Error(other) ->
      check.fail("rtc unexpected: " <> pico.error_to_string(other))
  }
}
