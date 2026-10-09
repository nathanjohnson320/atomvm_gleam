/// Typed Gleam wrappers for AtomVM's LED Controller (PWM) NIFs.
///
/// Source: [`libs/avm_esp32/src/ledc.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
/// Edoc fallback: [Module ledc](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
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
/// See [speed_mode()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
pub type SpeedMode {
  HighSpeed
  LowSpeed
}

/// Timer configuration for [`timer_config`](#timer_config).
///
/// See [timer_config()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
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
/// See [channel_config()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
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
/// See [speed_mode()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
pub fn high_speed_mode() -> SpeedMode {
  HighSpeed
}

/// Low-speed LEDC mode (`1`). Prefer this on ESP32-S3 backlight PWM.
///
/// See [speed_mode()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
pub fn low_speed_mode() -> SpeedMode {
  LowSpeed
}

/// Configure an LEDC timer.
///
/// See [`ledc:timer_config/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
pub fn timer_config(config: TimerConfig) -> Result(Nil, Error) {
  let TimerConfig(duty_resolution:, freq_hz:, speed_mode:, timer_num:) = config
  timer_config_ffi(duty_resolution, freq_hz, speed_mode, timer_num)
}

/// Configure an LEDC channel.
///
/// See [`ledc:channel_config/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
pub fn channel_config(config: ChannelConfig) -> Result(Nil, Error) {
  let ChannelConfig(
    channel:,
    duty:,
    gpio_num:,
    speed_mode:,
    hpoint:,
    timer_sel:,
  ) = config
  channel_config_ffi(channel, duty, gpio_num, speed_mode, hpoint, timer_sel)
}

/// Set channel duty (does not apply until [`update_duty`](#update_duty)).
///
/// See [`ledc:set_duty/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "set_duty")
pub fn set_duty(
  speed_mode: SpeedMode,
  channel: Int,
  duty: Int,
) -> Result(Nil, Error)

/// Apply pending duty changes for a channel.
///
/// See [`ledc:update_duty/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "update_duty")
pub fn update_duty(speed_mode: SpeedMode, channel: Int) -> Result(Nil, Error)

/// Install the LEDC fade function (occupies the LEDC interrupt).
///
/// See [`ledc:fade_func_install/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "fade_func_install")
pub fn fade_func_install(flags: Int) -> Result(Nil, Error)

/// Uninstall the LEDC fade function.
///
/// See [`ledc:fade_func_uninstall/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "fade_func_uninstall")
pub fn fade_func_uninstall() -> Result(Nil, Error)

/// Configure a time-limited fade. Call [`fade_start`](#fade_start) afterward.
///
/// See [`ledc:set_fade_with_time/4`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "set_fade_with_time")
pub fn set_fade_with_time(
  speed_mode: SpeedMode,
  channel: Int,
  target_duty: Int,
  max_fade_time_ms: Int,
) -> Result(Nil, Error)

/// Configure a step-based fade. Call [`fade_start`](#fade_start) afterward.
///
/// See [`ledc:set_fade_with_step/5`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "set_fade_with_step")
pub fn set_fade_with_step(
  speed_mode: SpeedMode,
  channel: Int,
  target_duty: Int,
  scale: Int,
  cycle_num: Int,
) -> Result(Nil, Error)

/// Atomically configure a time-limited fade and start it.
///
/// See [`ledc:set_fade_time_and_start/5`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "set_fade_time_and_start")
pub fn set_fade_time_and_start(
  speed_mode: SpeedMode,
  channel: Int,
  target_duty: Int,
  max_fade_time_ms: Int,
  fade_mode: Int,
) -> Result(Nil, Error)

/// Atomically configure a step-based fade and start it.
///
/// See [`ledc:set_fade_step_and_start/6`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "set_fade_step_and_start")
pub fn set_fade_step_and_start(
  speed_mode: SpeedMode,
  channel: Int,
  target_duty: Int,
  scale: Int,
  cycle_num: Int,
  fade_mode: Int,
) -> Result(Nil, Error)

/// Start a previously configured fade.
///
/// See [`ledc:fade_start/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "fade_start")
pub fn fade_start(
  speed_mode: SpeedMode,
  channel: Int,
  fade_mode: Int,
) -> Result(Nil, Error)

/// Stop an in-progress fade (platforms with `SOC_LEDC_SUPPORT_FADE_STOP` only).
///
/// See [`ledc:fade_stop/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "fade_stop")
pub fn fade_stop(speed_mode: SpeedMode, channel: Int) -> Result(Nil, Error)

/// Set duty and hpoint and apply them immediately (thread-safe).
///
/// See [`ledc:set_duty_and_update/4`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "set_duty_and_update")
pub fn set_duty_and_update(
  speed_mode: SpeedMode,
  channel: Int,
  duty: Int,
  hpoint: Int,
) -> Result(Nil, Error)

/// Read the current duty for a channel.
///
/// See [`ledc:get_duty/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "get_duty")
pub fn get_duty(speed_mode: SpeedMode, channel: Int) -> Result(Int, Error)

/// Read the current timer frequency in Hz.
///
/// See [`ledc:get_freq/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "get_freq")
pub fn get_freq(speed_mode: SpeedMode, timer_num: Int) -> Result(Int, Error)

/// Set the timer frequency in Hz.
///
/// See [`ledc:set_freq/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "set_freq")
pub fn set_freq(
  speed_mode: SpeedMode,
  timer_num: Int,
  freq_hz: Int,
) -> Result(Nil, Error)

/// Stop LEDC output on a channel and set the idle level.
///
/// See [`ledc:stop/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/ledc.erl).
@external(erlang, "atomvm_gleam_ledc_ffi", "stop")
pub fn stop(
  speed_mode: SpeedMode,
  channel: Int,
  idle_level: Int,
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
