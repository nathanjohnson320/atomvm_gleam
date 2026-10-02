/// Typed Gleam wrappers for AtomVM ESP32-specific APIs (`esp` module).
///
/// Source: [`libs/avm_esp32/src/esp.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl).
/// Edoc fallback: [Module esp](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html).
import gleam/option.{type Option}

/// Errors from ESP NIFs and helpers.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  NotFound
  Other(String)
}

/// Why the chip last restarted.
///
/// See [esp_reset_reason()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#esp-reset-reason).
pub type ResetReason {
  EspRstUnknown
  EspRstPoweron
  EspRstExt
  EspRstSw
  EspRstPanic
  EspRstIntWdt
  EspRstTaskWdt
  EspRstWdt
  EspRstDeepsleep
  EspRstBrownout
  EspRstSdio
  OtherReason(String)
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    NotFound -> "not_found"
    Other(reason) -> reason
  }
}

/// Read a binary from NVS, or `None` when the key is absent.
///
/// `namespace` and `key` are turned into Erlang atoms.
///
/// See [`esp:nvs_get_binary/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#nvs-get-binary-2).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_get_binary")
pub fn nvs_get_binary(
  namespace: String,
  key: String,
) -> Result(Option(BitArray), Error)

/// Write a binary to NVS (`esp:nvs_put_binary/3`).
///
/// See [`esp:nvs_put_binary/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#nvs-put-binary-3).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_put_binary")
pub fn nvs_put_binary(
  namespace: String,
  key: String,
  value: BitArray,
) -> Result(Nil, Error)

/// Erase a key from NVS.
///
/// See [`esp:nvs_erase_key/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#nvs-erase-key-2).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_erase_key")
pub fn nvs_erase_key(namespace: String, key: String) -> Result(Nil, Error)

/// Factory-programmed default MAC address (6 bytes).
///
/// See [`esp:get_default_mac/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#get-default-mac-0).
@external(erlang, "atomvm_gleam_esp_ffi", "get_default_mac")
pub fn get_default_mac() -> Result(BitArray, Error)

/// Reason for the last restart.
///
/// See [`esp:reset_reason/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#reset-reason-0).
@external(erlang, "atomvm_gleam_esp_ffi", "reset_reason")
pub fn reset_reason() -> ResetReason

/// Restart the ESP device. Does not return on success.
///
/// See [`esp:restart/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#restart-0).
@external(erlang, "atomvm_gleam_esp_ffi", "restart")
pub fn restart() -> Nil

/// Enable GPIO wake from light sleep (after `gpio:wakeup_enable/2`).
///
/// See [`esp:sleep_enable_gpio_wakeup/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#sleep-enable-gpio-wakeup-0).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_gpio_wakeup")
pub fn sleep_enable_gpio_wakeup() -> Result(Nil, Error)

/// Enter light sleep until a configured wake source fires.
///
/// See [`esp:light_sleep/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#light-sleep-0).
@external(erlang, "atomvm_gleam_esp_ffi", "light_sleep")
pub fn light_sleep() -> Result(Nil, Error)
