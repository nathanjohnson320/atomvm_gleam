import gleam/erlang/process.{type Pid}

/// Opaque handle for the AtomVM GPIO driver port (`gpio:open/0` / `gpio:start/0`).
///
/// See [Module gpio](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html).
pub type Gpio

/// Errors from the AtomVM gpio driver.
///
/// Known reason atoms are Gleam constructors (so `{error, not_supported}` is
/// `Error(NotSupported)`). Bare AtomVM `error` becomes `Failed`. Anything else
/// lands in `Other` as a string because AtomVM types reasons as open `atom()`.
///
/// See [Module gpio](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html).
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// Pin direction. Zero-arity variants encode as Erlang atoms matching
/// `gpio:set_direction/3` (`input`, `output`, `output_od`).
///
/// See [direction()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#direction).
pub type Direction {
  Input
  Output
  OutputOd
}

/// Interrupt trigger. Encodes as Erlang atoms matching `gpio:set_int/3`.
///
/// See [trigger()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#trigger).
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
/// See [level()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#level).
pub type Level {
  PinHigh
  PinLow
}

/// Internal resistor pull mode.
///
/// See [pull()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#pull).
pub type Pull {
  Up
  Down
  UpDown
  Floating
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
/// See [`gpio:open/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#open-0).
@external(erlang, "atomvm_gleam_gpio_ffi", "open")
pub fn open() -> Result(Gpio, Error)

/// Start the GPIO driver port, or return the existing one.
///
/// See [`gpio:start/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#start-0).
@external(erlang, "atomvm_gleam_gpio_ffi", "start")
pub fn start() -> Result(Gpio, Error)

/// Stop the GPIO interrupt port and free its resources.
///
/// See [`gpio:close/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#close-1).
@external(erlang, "atomvm_gleam_gpio_ffi", "close")
pub fn close(gpio: Gpio) -> Result(Nil, Error)

/// Stop the GPIO interrupt port (no handle required).
///
/// See [`gpio:stop/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#stop-0).
@external(erlang, "atomvm_gleam_gpio_ffi", "stop")
pub fn stop() -> Result(Nil, Error)

/// Set the operational mode of a pin (`input`, `output`, or `output_od`).
///
/// See [`gpio:set_direction/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#set-direction-3).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_direction")
pub fn set_direction(
  gpio: Gpio,
  pin: Int,
  direction: Direction,
) -> Result(Nil, Error)

/// Set GPIO digital output level via the port API.
///
/// See [`gpio:set_level/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#set-level-3).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_level")
pub fn set_level(gpio: Gpio, pin: Int, level: Level) -> Result(Nil, Error)

/// Read the digital state of a pin via the port API.
///
/// See [`gpio:read/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#read-2).
@external(erlang, "atomvm_gleam_gpio_ffi", "read")
pub fn read(gpio: Gpio, pin: Int) -> Result(Level, Error)

/// Set a GPIO interrupt. Delivers `{gpio_interrupt, Pin}` to the caller.
///
/// See [`gpio:set_int/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#set-int-3).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_int")
pub fn set_int(gpio: Gpio, pin: Int, trigger: Trigger) -> Result(Nil, Error)

/// Set a GPIO interrupt, delivering `{gpio_interrupt, Pin}` to `pid`.
///
/// See [`gpio:set_int/4`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#set-int-4).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_int_to")
pub fn set_int_to(
  gpio: Gpio,
  pin: Int,
  trigger: Trigger,
  pid: Pid,
) -> Result(Nil, Error)

/// Remove a GPIO interrupt.
///
/// See [`gpio:remove_int/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#remove-int-2).
@external(erlang, "atomvm_gleam_gpio_ffi", "remove_int")
pub fn remove_int(gpio: Gpio, pin: Int) -> Result(Nil, Error)

/// Convenience for `set_int/3` using only pin and trigger.
/// Prefer `set_int` when arming more than one pin.
///
/// See [`gpio:attach_interrupt/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#attach-interrupt-2).
@external(erlang, "atomvm_gleam_gpio_ffi", "attach_interrupt")
pub fn attach_interrupt(pin: Int, trigger: Trigger) -> Result(Nil, Error)

/// Convenience for `remove_int/2` using only the pin number.
///
/// See [`gpio:detach_interrupt/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#detach-interrupt-1).
@external(erlang, "atomvm_gleam_gpio_ffi", "detach_interrupt")
pub fn detach_interrupt(pin: Int) -> Result(Nil, Error)

/// Initialize a pin for GPIO use (required on RP2040; some ESP32 pins).
///
/// See [`gpio:init/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#init-1).
@external(erlang, "atomvm_gleam_gpio_ffi", "init")
pub fn init(pin: Int) -> Result(Nil, Error)

/// Reset a pin back to the NULL function (RP2040).
///
/// See [`gpio:deinit/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#deinit-1).
@external(erlang, "atomvm_gleam_gpio_ffi", "deinit")
pub fn deinit(pin: Int) -> Result(Nil, Error)

/// Set pin mode without a port handle (NIF-style API).
///
/// See [`gpio:set_pin_mode/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#set-pin-mode-2).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_pin_mode")
pub fn set_pin_mode(pin: Int, direction: Direction) -> Result(Nil, Error)

/// Set the internal resistor of a pin (not used on STM32).
///
/// See [`gpio:set_pin_pull/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#set-pin-pull-2).
@external(erlang, "atomvm_gleam_gpio_ffi", "set_pin_pull")
pub fn set_pin_pull(pin: Int, pull: Pull) -> Result(Nil, Error)

/// Read pin level via the NIF-style API.
///
/// See [`gpio:digital_read/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#digital-read-1).
@external(erlang, "atomvm_gleam_gpio_ffi", "digital_read")
pub fn digital_read(pin: Int) -> Result(Level, Error)

/// Write pin level via the NIF-style API.
///
/// See [`gpio:digital_write/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#digital-write-2).
@external(erlang, "atomvm_gleam_gpio_ffi", "digital_write")
pub fn digital_write(pin: Int, level: Level) -> Result(Nil, Error)

/// Hold the state of a pin (ESP32).
///
/// See [`gpio:hold_en/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#hold-en-1).
@external(erlang, "atomvm_gleam_gpio_ffi", "hold_en")
pub fn hold_en(pin: Int) -> Result(Nil, Error)

/// Release a pin from a hold state (ESP32).
///
/// See [`gpio:hold_dis/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#hold-dis-1).
@external(erlang, "atomvm_gleam_gpio_ffi", "hold_dis")
pub fn hold_dis(pin: Int) -> Result(Nil, Error)

/// Enable all hold functions to continue in deep sleep (ESP32).
///
/// See [`gpio:deep_sleep_hold_en/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#deep-sleep-hold-en-0).
@external(erlang, "atomvm_gleam_gpio_ffi", "deep_sleep_hold_en")
pub fn deep_sleep_hold_en() -> Result(Nil, Error)

/// Disable all gpio pad hold functions during deep sleep (ESP32).
///
/// See [`gpio:deep_sleep_hold_dis/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#deep-sleep-hold-dis-0).
@external(erlang, "atomvm_gleam_gpio_ffi", "deep_sleep_hold_dis")
pub fn deep_sleep_hold_dis() -> Result(Nil, Error)

/// Configure a GPIO as a light-sleep wakeup pin (ESP32).
///
/// See [`gpio:wakeup_enable/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/gpio.html#wakeup-enable-2).
@external(erlang, "atomvm_gleam_gpio_ffi", "wakeup_enable")
pub fn wakeup_enable(pin: Int, level: Level) -> Result(Nil, Error)
