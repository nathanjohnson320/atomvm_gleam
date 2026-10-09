//// GPIO port API (`open` / `set_direction` / …).
////
//// - ESP32 / STM32: port driver is owned — calls must succeed (IRQ too).
//// - Pico (gpio_hal): open / direction / level / read / close must Ok;
////   interrupts return NotSupported. If rp2040js still rejects direction,
////   honest SKIP — never soft-pass as coverage.
//// - GenericUnix: sysfs nif only (`gpio_unix_test`) — port exports NotSupported.
//// - Emscripten: no-op (unresolved gpio NIFs can abort Node WASM).

import atomvm_gleam/atomvm
import atomvm_gleam/gpio
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/erlang/process
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    atomvm.Esp32 -> gpio_port_must_work()
    atomvm.Stm32 -> gpio_port_stm32()
    atomvm.Pico -> gpio_port_pico()
    atomvm.GenericUnix -> gpio_port_absent_on_unix()
  }
}

fn gpio_ns(e: gpio.Error) -> Bool {
  case e {
    gpio.NotSupported -> True
    gpio.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
  }
}

fn gpio_port_must_work() -> Result(Nil, Failure) {
  use g <- result.try(expect.must_ok_value(
    "gpio.open",
    gpio.open(),
    gpio.error_to_string,
  ))
  let pin = gpio.pin(18)
  use _ <- result.try(expect.must_ok(
    "gpio.set_direction",
    gpio.set_direction(g, pin, gpio.Output),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.set_level",
    gpio.set_level(g, pin, gpio.PinHigh),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.read",
    gpio.read(g, pin),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.set_int",
    gpio.set_int(g, pin, gpio.Rising),
    gpio.error_to_string,
  ))
  let _ = gpio.remove_int(g, pin)
  use _ <- result.try(expect.must_ok(
    "gpio.set_int_to",
    gpio.set_int_to(g, pin, gpio.Rising, process.self()),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.remove_int",
    gpio.remove_int(g, pin),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.attach_interrupt",
    gpio.attach_interrupt(pin, gpio.Rising),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.detach_interrupt",
    gpio.detach_interrupt(pin),
    gpio.error_to_string,
  ))
  // QEMU may return bare `error` on close/stop after interrupt arming.
  use _ <- result.try(expect.ok_or_runtime(
    "gpio.close",
    gpio.close(g),
    fn(e) {
      case e {
        gpio.Failed | gpio.Badarg -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "gpio.start",
    gpio.start(),
    fn(e) {
      case e {
        gpio.Failed | gpio.Badarg -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "gpio.stop",
    gpio.stop(),
    fn(e) {
      case e {
        gpio.Failed | gpio.Badarg -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "gpio.deep_sleep_hold_en",
    gpio.deep_sleep_hold_en(),
    fn(e) {
      case e {
        gpio.Failed | gpio.Badarg -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "gpio.deep_sleep_hold_dis",
    gpio.deep_sleep_hold_dis(),
    fn(e) {
      case e {
        gpio.Failed | gpio.Badarg -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "gpio.wakeup_enable",
    gpio.wakeup_enable(pin, gpio.PinLow),
    fn(e) {
      case e {
        gpio.Failed | gpio.Badarg -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  Ok(Nil)
}

fn gpio_port_stm32() -> Result(Nil, Failure) {
  use g <- result.try(expect.must_ok_value(
    "gpio.open",
    gpio.open(),
    gpio.error_to_string,
  ))
  let pin = gpio.bank(gpio.B, 7)
  use _ <- result.try(expect.must_ok(
    "gpio.set_direction",
    gpio.set_direction(g, pin, gpio.Output),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.set_level",
    gpio.set_level(g, pin, gpio.PinHigh),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.read",
    gpio.read(g, pin),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.set_int",
    gpio.set_int(g, pin, gpio.Rising),
    gpio.error_to_string,
  ))
  let _ = gpio.remove_int(g, pin)
  expect.must_ok("gpio.close", gpio.close(g), gpio.error_to_string)
}

fn gpio_port_pico() -> Result(Nil, Failure) {
  use g <- result.try(expect.must_ok_value(
    "gpio.open",
    gpio.open(),
    gpio.error_to_string,
  ))
  let pin = gpio.pin(18)
  // gpio_hal: direction/level/read must work on RP2. rp2040js may still reject
  // port direction — honest SKIP, not soft coverage.
  case gpio.set_direction(g, pin, gpio.Output) {
    Error(gpio.NotSupported) -> {
      let _ = gpio.close(g)
      integration.skip("rp2040js port direction (gpio_hal expects Ok on hardware)")
    }
    Error(reason) -> {
      let _ = gpio.close(g)
      check.fail("gpio.set_direction: " <> gpio.error_to_string(reason))
    }
    Ok(_) -> {
      use _ <- result.try(check.cover("gpio.set_direction", check.ok()))
      use _ <- result.try(expect.must_ok(
        "gpio.set_level",
        gpio.set_level(g, pin, gpio.PinHigh),
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.must_ok(
        "gpio.read",
        gpio.read(g, pin),
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.must_not_supported(
        "gpio.set_int",
        gpio.set_int(g, pin, gpio.Rising),
        gpio_ns,
        gpio.error_to_string,
      ))
      expect.must_ok("gpio.close", gpio.close(g), gpio.error_to_string)
    }
  }
}

fn gpio_port_absent_on_unix() -> Result(Nil, Failure) {
  use _ <- result.try(expect.must_not_supported(
    "gpio.open",
    gpio.open(),
    gpio_ns,
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_not_supported(
    "gpio.start",
    gpio.start(),
    gpio_ns,
    gpio.error_to_string,
  ))
  Ok(Nil)
}
