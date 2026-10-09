//// Pico / RP2-specific AtomVM APIs (`pico` module).
////
//// CYW43 GPIO helpers are **Pico-W only**. The onboard LED is typically
//// CYW43 GPIO `0`.
////
//// Source: [`libs/avm_rp2/src/pico.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/pico.erl#L1).
//// Docs: [Module pico](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/pico.erl#L1).

/// Errors from Pico NIFs and helpers.
///
/// Known reason atoms are Gleam constructors (so `{error, not_supported}` is
/// `Error(NotSupported)`). Bare AtomVM `error` becomes `Failed`. Anything else
/// lands in `Other` as a string.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// Digital level for CYW43 GPIO write. Mapped to Erlang `0` / `1` in FFI
/// (matching upstream `pico:cyw43_arch_gpio_put/2`).
///
/// Naming matches `gpio.Level` (`PinHigh` / `PinLow`).
pub type Level {
  PinHigh
  PinLow
}

/// Erlang `calendar:date()` - `{Year, Month, Day}`.
pub type Date {
  Date(year: Int, month: Int, day: Int)
}

/// Erlang `calendar:time()` - `{Hour, Minute, Second}`.
pub type TimeOfDay {
  TimeOfDay(hour: Int, minute: Int, second: Int)
}

/// Erlang `calendar:datetime()` - `{{Year, Month, Day}, {Hour, Minute, Second}}`.
pub type DateTime {
  DateTime(date: Date, time: TimeOfDay)
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

/// Read a CYW43 GPIO pin (`0..2`). Pico-W only. Returns `0` or `1`.
///
/// See [`pico:cyw43_arch_gpio_get/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/pico.erl#L52).
@external(erlang, "atomvm_gleam_pico_ffi", "cyw43_arch_gpio_get")
pub fn cyw43_arch_gpio_get(gpio: Int) -> Result(Int, Error)

/// Write a CYW43 GPIO pin (`0..2`). Pico-W only. Typically drives the onboard LED (GPIO `0`).
///
/// See [`pico:cyw43_arch_gpio_put/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/pico.erl#L64).
pub fn cyw43_arch_gpio_put(gpio: Int, level: Level) -> Result(Nil, Error) {
  cyw43_arch_gpio_put_ffi(gpio, level)
}

/// Set the RTC clock from a `calendar:datetime()`-shaped value.
///
/// See [`pico:rtc_set_datetime/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/pico.erl#L41).
pub fn rtc_set_datetime(datetime: DateTime) -> Result(Nil, Error) {
  let DateTime(date:, time:) = datetime
  let Date(year:, month:, day:) = date
  let TimeOfDay(hour:, minute:, second:) = time
  rtc_set_datetime_ffi(year, month, day, hour, minute, second)
}

@external(erlang, "atomvm_gleam_pico_ffi", "cyw43_arch_gpio_put")
fn cyw43_arch_gpio_put_ffi(gpio: Int, level: Level) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_pico_ffi", "rtc_set_datetime")
fn rtc_set_datetime_ffi(
  year: Int,
  month: Int,
  day: Int,
  hour: Int,
  minute: Int,
  second: Int,
) -> Result(Nil, Error)
