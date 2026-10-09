//// GPIO port API — Ok-or-NotSupported across platforms.

import atomvm_gleam/atomvm
import atomvm_gleam/gpio
import avm/check.{type Failure}
import avm/expect
import gleam/erlang/process
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  // Node WASM: unresolved gpio NIFs can abort the process instead of returning.
  case atomvm.platform() {
    atomvm.Emscripten -> gpio_absent_tags()
    _ -> gpio_port_api_live()
  }
}

fn gpio_ns(e: gpio.Error) -> Bool {
  case e {
    // Pico exposes gpio.open but rejects ESP-style port ops (badarg/fail).
    gpio.NotSupported | gpio.Failed | gpio.Badarg -> True
    gpio.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
  }
}

fn gpio_absent_tags() -> Result(Nil, Failure) {
  use _ <- result.try(check.cover_not_supported("gpio.open"))
  use _ <- result.try(check.cover_not_supported("gpio.start"))
  use _ <- result.try(check.cover_not_supported("gpio.close"))
  use _ <- result.try(check.cover_not_supported("gpio.stop"))
  use _ <- result.try(check.cover_not_supported("gpio.set_direction"))
  use _ <- result.try(check.cover_not_supported("gpio.set_level"))
  use _ <- result.try(check.cover_not_supported("gpio.read"))
  use _ <- result.try(check.cover_not_supported("gpio.set_int"))
  use _ <- result.try(check.cover_not_supported("gpio.set_int_to"))
  use _ <- result.try(check.cover_not_supported("gpio.remove_int"))
  use _ <- result.try(check.cover_not_supported("gpio.attach_interrupt"))
  use _ <- result.try(check.cover_not_supported("gpio.detach_interrupt"))
  use _ <- result.try(check.cover_not_supported("gpio.deep_sleep_hold_en"))
  use _ <- result.try(check.cover_not_supported("gpio.deep_sleep_hold_dis"))
  use _ <- result.try(check.cover_not_supported("gpio.wakeup_enable"))
  Ok(Nil)
}

fn gpio_port_api_live() -> Result(Nil, Failure) {
  use g_r <- result.try(expect.ok_value_or_not_supported(
    "gpio.open",
    gpio.open(),
    gpio_ns,
    gpio.error_to_string,
  ))
  case g_r {
    Error(Nil) -> {
      use _ <- result.try(check.cover_not_supported("gpio.start"))
      use _ <- result.try(check.cover_not_supported("gpio.close"))
      use _ <- result.try(check.cover_not_supported("gpio.stop"))
      use _ <- result.try(check.cover_not_supported("gpio.set_direction"))
      use _ <- result.try(check.cover_not_supported("gpio.set_level"))
      use _ <- result.try(check.cover_not_supported("gpio.read"))
      use _ <- result.try(check.cover_not_supported("gpio.set_int"))
      use _ <- result.try(check.cover_not_supported("gpio.set_int_to"))
      use _ <- result.try(check.cover_not_supported("gpio.remove_int"))
      use _ <- result.try(check.cover_not_supported("gpio.attach_interrupt"))
      use _ <- result.try(check.cover_not_supported("gpio.detach_interrupt"))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.deep_sleep_hold_en",
        gpio.deep_sleep_hold_en(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.deep_sleep_hold_dis",
        gpio.deep_sleep_hold_dis(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.wakeup_enable",
        gpio.wakeup_enable(gpio.pin(0), gpio.PinLow),
        gpio_ns,
        gpio.error_to_string,
      ))
      Ok(Nil)
    }
    Ok(g) -> {
      let pin = gpio.pin(18)
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.set_direction",
        gpio.set_direction(g, pin, gpio.Output),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.set_level",
        gpio.set_level(g, pin, gpio.PinHigh),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.read",
        gpio.read(g, pin),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.set_int",
        gpio.set_int(g, pin, gpio.Rising),
        gpio_ns,
        gpio.error_to_string,
      ))
      // Driver allows only one listener per pin — detach before set_int_to.
      let _ = gpio.remove_int(g, pin)
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.set_int_to",
        gpio.set_int_to(g, pin, gpio.Rising, process.self()),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.remove_int",
        gpio.remove_int(g, pin),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.attach_interrupt",
        gpio.attach_interrupt(pin, gpio.Rising),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.detach_interrupt",
        gpio.detach_interrupt(pin),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.close",
        gpio.close(g),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.start",
        gpio.start(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.stop",
        gpio.stop(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.deep_sleep_hold_en",
        gpio.deep_sleep_hold_en(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.deep_sleep_hold_dis",
        gpio.deep_sleep_hold_dis(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.wakeup_enable",
        gpio.wakeup_enable(pin, gpio.PinLow),
        gpio_ns,
        gpio.error_to_string,
      ))
      Ok(Nil)
    }
  }
}
