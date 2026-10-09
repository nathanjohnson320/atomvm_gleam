//// Shared helpers for integration / workflow suites.
////
//// Soft hardware skips log `SKIP …` and return `Ok(Nil)` without coverage
//// tags — missing harness must not count as covered. Never follow a skip with
//// `cover_not_supported` for APIs that were not called.

import avm/check.{type Failure}
import avm/log
import gleam/option.{type Option}
import gleam/string

/// Log a skip and succeed the suite step (no cover tag).
pub fn skip(reason: String) -> Result(Nil, Failure) {
  log.line("SKIP " <> reason)
  Ok(Nil)
}

/// Read an environment variable (`None` if unset).
pub fn env(name: String) -> Option(String) {
  getenv(name)
}

/// True when env is set to a truthy value (`1`, `true`, `yes`, case-insensitive).
pub fn env_flag(name: String) -> Bool {
  case env(name) {
    option.None -> False
    option.Some(value) -> {
      let v = string.lowercase(string.trim(value))
      v == "1" || v == "true" || v == "yes"
    }
  }
}

/// Wi‑Fi credentials from `AVM_GLEAM_WIFI_SSID` / `AVM_GLEAM_WIFI_PSK`.
/// PSK may be empty (open network). Missing SSID → `None`.
pub fn wifi_creds() -> Option(#(String, String)) {
  case env("AVM_GLEAM_WIFI_SSID") {
    option.None -> option.None
    option.Some(ssid) -> {
      let psk = case env("AVM_GLEAM_WIFI_PSK") {
        option.None -> ""
        option.Some(p) -> p
      }
      option.Some(#(ssid, psk))
    }
  }
}

/// Sleep for `ms` milliseconds (`timer:sleep`).
pub fn sleep_ms(ms: Int) -> Nil {
  sleep_ms_ffi(ms)
}

/// Receive any mailbox message within `timeout_ms`, or `Error(Nil)` on timeout.
pub fn receive_any(timeout_ms: Int) -> Result(message, Nil) {
  case receive_any_ffi(timeout_ms) {
    Ok(msg) -> Ok(msg)
    Error(_) -> Error(Nil)
  }
}

@external(erlang, "avm_test_env_ffi", "getenv")
fn getenv(name: String) -> Option(String)

@external(erlang, "avm_test_env_ffi", "sleep_ms")
fn sleep_ms_ffi(ms: Int) -> Nil

@external(erlang, "avm_test_env_ffi", "receive_any")
fn receive_any_ffi(timeout_ms: Int) -> Result(message, String)
