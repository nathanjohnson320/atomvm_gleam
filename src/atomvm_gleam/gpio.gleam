//// Typed Gleam wrappers for AtomVM GPIO.
////
//// ESP32 source: [`libs/avm_esp32/src/gpio.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
//// RP2 source: [`libs/avm_rp2/src/gpio.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/gpio.erl).
//// UNIX source: [`libs/avm_unix/src/gpio.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_unix/src/gpio.erl).
//// Edoc: [`gpio_hal`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/gpio_hal.html).
////
//// On Pico-W, the onboard LED is the wireless-bank pin `WlPin(0)` (Erlang
//// `{wl, 0}`). Prefer `digital_write(wl(0), …)` for that LED; the forthcoming
//// `pico` module CYW43 helpers are an alternate API for the same hardware.

import gleam/erlang/process.{type Pid}

/// Opaque handle for the AtomVM GPIO driver port (`gpio:open/0` / `gpio:start/0`).
///
/// See ESP32 [`gpio.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl),
/// RP2 [`gpio.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/gpio.erl),
/// UNIX [`gpio.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_unix/src/gpio.erl).
pub type Gpio

/// Errors from the AtomVM gpio driver.
///
/// Known reason atoms are Gleam constructors (so `{error, not_supported}` is
/// `Error(NotSupported)`). Bare AtomVM `error` becomes `Failed`. Anything else
/// lands in `Other` as a string because AtomVM types reasons as open `atom()`.
///
/// See ESP32 [`gpio.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl),
/// RP2 [`gpio.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/gpio.erl),
/// UNIX [`gpio.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_unix/src/gpio.erl).
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// GPIO pin. `PinNum` is a plain GPIO number (ESP32 and RP2). `WlPin` is a
/// Pico-W wireless-bank pin (`{wl, N}`). `BankPin` is STM32 `{Bank, N}` where
/// `Bank` is an atom `a`..`k`.
///
/// Use `pin/1`, `wl/1`, and `bank/2` helpers at call sites. On Pico-W the
/// onboard LED is `wl(0)` / `WlPin(0)` (`{wl, 0}`); `pico` CYW43 helpers are an
/// alternate API. On STM32 prefer `bank(B, 7)` for PB7.
///
/// See [pin definitions](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/gpio_hal.html#pin-definitions).
pub type Pin {
  PinNum(Int)
  WlPin(Int)
  BankPin(GpioBank, Int)
}

/// STM32 GPIO bank letter (`a`..`k`), encoded as the matching Erlang atom.
pub type GpioBank {
  A
  B
  C
  D
  E
  F
  G
  H
  I
  J
  K
}

/// Wrap a numeric GPIO pin as `PinNum`.
pub fn pin(n: Int) -> Pin {
  PinNum(n)
}

/// Wrap a Pico-W wireless-bank pin as `WlPin` (Erlang `{wl, N}`).
///
/// Example: Pico-W LED is `wl(0)`.
pub fn wl(n: Int) -> Pin {
  WlPin(n)
}

/// Wrap an STM32 bank+pin as `BankPin` (Erlang `{Bank, N}`).
///
/// Example: Nucleo LED often `bank(C, 13)` / `{c, 13}`.
pub fn bank(bank: GpioBank, n: Int) -> Pin {
  BankPin(bank, n)
}

/// Pin direction. Zero-arity variants encode as Erlang atoms matching
/// `gpio:set_direction/3` (`input`, `output`, `output_od`).
///
/// See [direction()](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/gpio_hal.html#direction).
pub type Direction {
  Input
  Output
  OutputOd
}

/// Interrupt trigger. Encodes as Erlang atoms matching `gpio:set_int/3`.
///
/// See [trigger()](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/gpio_hal.html#trigger).
pub type Trigger {
  None
  Rising
  Falling
  Both
  Low
  High
}

/// Digital level. Encodes through FFI as Erlang `high` / `low` (distinct
/// constructors from `Trigger`, which also uses those atoms).
///
/// See [level()](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/gpio_hal.html#level).
pub type Level {
  PinHigh
  PinLow
}

/// Internal resistor pull mode.
///
/// See [pull()](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/gpio_hal.html#pull).
pub type Pull {
  Up
  Down
  UpDown
  Floating
}

/// RP2 GPIO function select (`gpio:set_function/2`). Encodes as Erlang atoms
/// matching Pico SDK `gpio_function_t`: `spi`, `uart`, `i2c`, `pwm`, `sio`,
/// `pio0`, `pio1`.
///
/// See [`gpio:set_function/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/gpio.erl).
pub type GpioFunction {
  Spi
  Uart
  I2c
  Pwm
  Sio
  Pio0
  Pio1
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    Other(reason) -> reason
  }
}

/// Start the GPIO driver port. Fails if it is already running.
///
/// See [`gpio:open/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "open")
pub fn open() -> Result(Gpio, Error)

/// Start the GPIO driver port, or return the existing one.
///
/// See [`gpio:start/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "start")
pub fn start() -> Result(Gpio, Error)

/// Stop the GPIO interrupt port and free its resources.
///
/// See [`gpio:close/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "close")
pub fn close(gpio: Gpio) -> Result(Nil, Error)

/// Stop the GPIO interrupt port (no handle required).
///
/// See [`gpio:stop/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "stop")
pub fn stop() -> Result(Nil, Error)

/// Set the operational mode of a pin (`input`, `output`, or `output_od`).
///
/// See [`gpio:set_direction/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_direction")
pub fn set_direction(
  gpio: Gpio,
  pin: Pin,
  direction: Direction,
) -> Result(Nil, Error)

/// Set GPIO digital output level via the port API.
///
/// See [`gpio:set_level/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_level")
pub fn set_level(gpio: Gpio, pin: Pin, level: Level) -> Result(Nil, Error)

/// Read the digital state of a pin via the port API.
///
/// See [`gpio:read/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "read")
pub fn read(gpio: Gpio, pin: Pin) -> Result(Level, Error)

/// Set a GPIO interrupt. Delivers `{gpio_interrupt, Pin}` to the caller.
///
/// See [`gpio:set_int/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_int")
pub fn set_int(gpio: Gpio, pin: Pin, trigger: Trigger) -> Result(Nil, Error)

/// Set a GPIO interrupt, delivering `{gpio_interrupt, Pin}` to `pid`.
///
/// See [`gpio:set_int/4`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_int_to")
pub fn set_int_to(
  gpio: Gpio,
  pin: Pin,
  trigger: Trigger,
  pid: Pid,
) -> Result(Nil, Error)

/// Remove a GPIO interrupt.
///
/// See [`gpio:remove_int/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "remove_int")
pub fn remove_int(gpio: Gpio, pin: Pin) -> Result(Nil, Error)

/// Convenience for `set_int/3` using only pin and trigger.
/// Prefer `set_int` when arming more than one pin.
///
/// See [`gpio:attach_interrupt/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "attach_interrupt")
pub fn attach_interrupt(pin: Pin, trigger: Trigger) -> Result(Nil, Error)

/// Convenience for `remove_int/2` using only the pin.
///
/// See [`gpio:detach_interrupt/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "detach_interrupt")
pub fn detach_interrupt(pin: Pin) -> Result(Nil, Error)

/// Initialize a pin for GPIO use (required on RP2040; some ESP32 pins).
///
/// See [`gpio:init/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/gpio.erl)
/// and ESP32 [`gpio.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "init")
pub fn init(pin: Pin) -> Result(Nil, Error)

/// Reset a pin back to the NULL function (RP2040).
///
/// See [`gpio:deinit/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "deinit")
pub fn deinit(pin: Pin) -> Result(Nil, Error)

/// Select the function for a GPIO pin (RP2 / Pico SDK `gpio_set_function`).
/// Takes a numeric pin only; wireless-bank pins are not supported by upstream.
///
/// See [`gpio:set_function/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_function")
pub fn set_function(pin: Int, function: GpioFunction) -> Result(Nil, Error)

/// Set pin mode without a port handle (NIF-style API).
///
/// See [`gpio:set_pin_mode/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_pin_mode")
pub fn set_pin_mode(pin: Pin, direction: Direction) -> Result(Nil, Error)

/// Set the internal resistor of a pin (not used on STM32).
///
/// See [`gpio:set_pin_pull/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_pin_pull")
pub fn set_pin_pull(pin: Pin, pull: Pull) -> Result(Nil, Error)

/// Read pin level via the NIF-style API.
///
/// On Pico-W, VBUS detect is readable as `wl(2)` without prior mode/pull setup.
///
/// See [`gpio:digital_read/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "digital_read")
pub fn digital_read(pin: Pin) -> Result(Level, Error)

/// Write pin level via the NIF-style API.
///
/// On Pico-W, the onboard LED is `wl(0)` / `{wl, 0}` and does not require
/// `set_pin_mode` or `set_pin_pull` before use. The `pico` module CYW43 helpers
/// are an alternate API for the same LED.
///
/// See [`gpio:digital_write/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "digital_write")
pub fn digital_write(pin: Pin, level: Level) -> Result(Nil, Error)

/// Hold the state of a pin (ESP32).
///
/// See [`gpio:hold_en/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "hold_en")
pub fn hold_en(pin: Pin) -> Result(Nil, Error)

/// Release a pin from a hold state (ESP32).
///
/// See [`gpio:hold_dis/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "hold_dis")
pub fn hold_dis(pin: Pin) -> Result(Nil, Error)

/// Enable all hold functions to continue in deep sleep (ESP32).
///
/// See [`gpio:deep_sleep_hold_en/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "deep_sleep_hold_en")
pub fn deep_sleep_hold_en() -> Result(Nil, Error)

/// Disable all gpio pad hold functions during deep sleep (ESP32).
///
/// See [`gpio:deep_sleep_hold_dis/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "deep_sleep_hold_dis")
pub fn deep_sleep_hold_dis() -> Result(Nil, Error)

/// Configure a GPIO as a light-sleep wakeup pin (ESP32).
///
/// See [`gpio:wakeup_enable/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "wakeup_enable")
pub fn wakeup_enable(pin: Pin, level: Level) -> Result(Nil, Error)

/// Override the sysfs GPIO base directory (generic UNIX / Linux only).
///
/// Defaults to `/sys/class/gpio`. Useful for tests that stub a sysfs tree.
/// Not available on ESP32 / RP2 / STM32 builds.
///
/// See [`gpio:set_sysfs_base/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_unix/src/gpio.erl).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_sysfs_base")
pub fn set_sysfs_base(dir: String) -> Result(Nil, Error)
