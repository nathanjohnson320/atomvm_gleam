/// Typed Gleam wrappers for AtomVM's LED Controller (PWM) NIFs.
///
/// Source: [`libs/avm_esp32/src/ledc.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
/// Edoc fallback: [Module ledc](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ledc.html).
import gleam/int

/// Errors from the LEDC NIFs.
///
/// AtomVM returns `{error, ledc_error_code()}` with a numeric IDF code, or
/// known atoms; bare `error` becomes `Failed`.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  /// ESP-IDF LEDC error code from `{error, Code}` when `Code` is an integer.
  Code(Int)
  Other(String)
}

/// LEDC speed mode. AtomVM uses `0` for high speed and `1` for low speed.
///
/// See [speed_mode()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ledc.html#speed-mode).
pub type SpeedMode {
  HighSpeed
  LowSpeed
}

/// Timer configuration for [`timer_config`](#timer_config).
///
/// See [timer_config()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ledc.html#timer-config).
pub type TimerConfig {
  TimerConfig(
    duty_resolution: Int,
    freq_hz: Int,
    speed_mode: SpeedMode,
    timer_num: Int,
  )
}

/// Channel configuration for [`channel_config`](#channel_config).
///
/// See [channel_config()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ledc.html#channel-config).
pub type ChannelConfig {
  ChannelConfig(
    channel: Int,
    duty: Int,
    gpio_num: Int,
    speed_mode: SpeedMode,
    hpoint: Int,
    timer_sel: Int,
  )
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    Code(code) -> "ledc_error_" <> int.to_string(code)
    Other(reason) -> reason
  }
}

/// High-speed LEDC mode (`0`).
///
/// See [speed_mode()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ledc.html#speed-mode).
pub fn high_speed_mode() -> SpeedMode {
  HighSpeed
}

/// Low-speed LEDC mode (`1`). Prefer this on ESP32-S3 backlight PWM.
///
/// See [speed_mode()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ledc.html#speed-mode).
pub fn low_speed_mode() -> SpeedMode {
  LowSpeed
}

/// Configure an LEDC timer.
///
/// See [`ledc:timer_config/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ledc.html#timer-config-1).
pub fn timer_config(config: TimerConfig) -> Result(Nil, Error) {
  let TimerConfig(duty_resolution:, freq_hz:, speed_mode:, timer_num:) = config
  timer_config_ffi(duty_resolution, freq_hz, speed_mode, timer_num)
}

/// Configure an LEDC channel.
///
/// See [`ledc:channel_config/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ledc.html#channel-config-1).
pub fn channel_config(config: ChannelConfig) -> Result(Nil, Error) {
  let ChannelConfig(channel:, duty:, gpio_num:, speed_mode:, hpoint:, timer_sel:) =
    config
  channel_config_ffi(channel, duty, gpio_num, speed_mode, hpoint, timer_sel)
}

/// Set channel duty (does not apply until [`update_duty`](#update_duty)).
///
/// See [`ledc:set_duty/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ledc.html#set-duty-3).
@external(erlang, "atomvm_gleam_ledc_ffi", "set_duty")
pub fn set_duty(
  speed_mode: SpeedMode,
  channel: Int,
  duty: Int,
) -> Result(Nil, Error)

/// Apply pending duty changes for a channel.
///
/// See [`ledc:update_duty/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/ledc.html#update-duty-2).
@external(erlang, "atomvm_gleam_ledc_ffi", "update_duty")
pub fn update_duty(
  speed_mode: SpeedMode,
  channel: Int,
) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_ledc_ffi", "timer_config")
fn timer_config_ffi(
  duty_resolution: Int,
  freq_hz: Int,
  speed_mode: SpeedMode,
  timer_num: Int,
) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_ledc_ffi", "channel_config")
fn channel_config_ffi(
  channel: Int,
  duty: Int,
  gpio_num: Int,
  speed_mode: SpeedMode,
  hpoint: Int,
  timer_sel: Int,
) -> Result(Nil, Error)