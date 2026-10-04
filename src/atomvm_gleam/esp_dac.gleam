//// ESP32 digital-to-analog converter (DAC) oneshot channel APIs.
////
//// Source: [`libs/avm_esp32/src/esp_dac.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp_dac.erl).
////
//// ESP32 classic has two 8-bit DAC channels (`chan_id` `0` and `1`). Create a
//// oneshot channel, write a level with [`oneshot_output_voltage`](#oneshot_output_voltage),
//// then release it with [`oneshot_del_channel`](#oneshot_del_channel).

/// Opaque DAC channel resource from [`new_channel`](#new_channel).
///
/// Matches upstream `dac_rsrc()`.
pub type Channel

/// Errors from the AtomVM ESP32 DAC NIFs.
///
/// Known reason atoms are Gleam constructors (so `{error, badarg}` is
/// `Error(Badarg)`). Bare AtomVM `error` becomes `Failed`. Anything else
/// lands in `Other` as a string because AtomVM types reasons as open `term()`.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// Channel creation mode for [`new_channel`](#new_channel).
///
/// Upstream currently supports only `oneshot`.
pub type Mode {
  Oneshot
}

/// Options for oneshot channel creation (`oneshot_channel_opts()`).
///
/// `chan_id` must be `0` or `1`.
pub type OneshotOptions {
  OneshotOptions(chan_id: Int)
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

/// Allocate a DAC channel. Pass [`Oneshot`](#Mode) and
/// [`OneshotOptions`](#OneshotOptions) with `chan_id` `0` or `1`.
///
/// See [`esp_dac:new_channel/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp_dac.erl).
pub fn new_channel(
  mode: Mode,
  options: OneshotOptions,
) -> Result(Channel, Error) {
  let OneshotOptions(chan_id:) = options
  case mode {
    Oneshot -> new_channel_ffi(chan_id)
  }
}

/// Set the oneshot output voltage level (`0..255`) on a channel from
/// [`new_channel`](#new_channel).
///
/// See [`esp_dac:oneshot_output_voltage/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp_dac.erl).
@external(erlang, "atomvm_gleam_esp_dac_ffi", "oneshot_output_voltage")
pub fn oneshot_output_voltage(
  channel: Channel,
  level: Int,
) -> Result(Nil, Error)

/// Delete a oneshot DAC channel and release its resource.
///
/// See [`esp_dac:oneshot_del_channel/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp_dac.erl).
@external(erlang, "atomvm_gleam_esp_dac_ffi", "oneshot_del_channel")
pub fn oneshot_del_channel(channel: Channel) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_esp_dac_ffi", "new_channel")
fn new_channel_ffi(chan_id: Int) -> Result(Channel, Error)
