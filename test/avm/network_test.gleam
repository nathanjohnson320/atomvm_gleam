//// Network / Wi‑Fi - owned on ESP32 and Pico-W (avm_network + radio).
//// STM32 / unix / non-W Pico / WASM: no radio HAL → NotSupported or no-radio
//// runtime. Emulators hang on `start` → SKIP unless `AVM_GLEAM_INTEGRATION=1`
//// on a board with Wi‑Fi (ESP or Pico-W). Creds: `AVM_GLEAM_WIFI_SSID` /
//// `AVM_GLEAM_WIFI_PSK` (defaults used only for API smoke when unset).

import atomvm_gleam/atomvm
import atomvm_gleam/network
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/erlang/process
import gleam/option
import gleam/result
import gleam/string

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    atomvm.Esp32 -> network_wifi_owned("ESP32 QEMU hang on start")
    atomvm.Pico -> network_wifi_owned("needs Pico-W firmware + radio")
    atomvm.GenericUnix | atomvm.Stm32 -> network_off_platform()
  }
}

fn network_ns(e: network.Error) -> Bool {
  case e {
    network.NotSupported -> True
    network.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
  }
}

fn network_runtime(e: network.Error) -> Bool {
  case e {
    network.Failed | network.Disconnected | network.Timeout -> True
    network.Other(reason) ->
      reason == "network_down" || string.contains(reason, "already_started")
    _ -> False
  }
}

fn network_wait(
  id: String,
  outcome: Result(a, network.Error),
) -> Result(Nil, Failure) {
  case outcome {
    Ok(_) -> check.cover(id, check.ok())
    Error(network.Timeout) -> check.cover(id, check.ok())
    Error(other) ->
      case network_runtime(other) {
        True -> check.cover(id, check.ok())
        False -> check.fail(id <> ": " <> network.error_to_string(other))
      }
  }
}

fn network_off_platform() -> Result(Nil, Failure) {
  // Module may be packed (unix) but there is no Wi‑Fi STA - expect
  // NotSupported / undef, or a no-radio runtime error. Ok(connected) would be wrong.
  case network.sta_status() {
    Error(reason) ->
      case network_ns(reason) || network_runtime(reason) {
        True -> check.cover_not_supported("network.sta_status")
        False ->
          check.fail(
            "network.sta_status: unexpected off-radio error: "
            <> network.error_to_string(reason),
          )
      }
    Ok(status) ->
      check.fail(
        "network.sta_status: unexpected Ok without radio ("
        <> network.sta_status_to_string(status)
        <> ")",
      )
  }
}

fn network_wifi_owned(skip_why: String) -> Result(Nil, Failure) {
  case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False ->
      integration.skip(
        "network.* (" <> skip_why <> "; set AVM_GLEAM_INTEGRATION=1)",
      )
    True -> network_wifi_live()
  }
}

fn wifi_ssid_psk() -> #(String, String) {
  case integration.wifi_creds() {
    option.Some(#(ssid, psk)) -> #(ssid, psk)
    option.None -> #("avm_gleam_test", "password")
  }
}

fn network_wifi_live() -> Result(Nil, Failure) {
  let #(ssid, psk) = wifi_ssid_psk()
  let sta =
    network.StaConfig(
      managed: True,
      ssid: option.Some(ssid),
      psk: option.Some(psk),
      dhcp_hostname: option.None,
      notify: process.self(),
    )
  use _ <- result.try(expect.ok_or_runtime(
    "network.start",
    network.start(sta, option.None),
    network_runtime,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "network.start_link",
    network.start_link(sta, option.None),
    network_runtime,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "network.start_with",
    network.start_with(option.Some(sta), option.None, option.None, option.None),
    network_runtime,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "network.start_link_with",
    network.start_link_with(
      option.Some(sta),
      option.None,
      option.None,
      option.None,
    ),
    network_runtime,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "network.sta_connect",
    network.sta_connect(),
    network_runtime,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "network.sta_connect_to",
    network.sta_connect_to(ssid, psk),
    network_runtime,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "network.sta_disconnect",
    network.sta_disconnect(),
    network_runtime,
    network.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "network.wifi_scan_default",
    network.wifi_scan_default(),
    network.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "network.wifi_scan",
    network.wifi_scan(4),
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "network.sta_rssi",
    network.sta_rssi(),
    network_runtime,
    network.error_to_string,
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_sta_timeout",
    network.wait_for_sta_timeout(10),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_sta_config",
    network.wait_for_sta_config(option.Some(ssid), option.Some(psk)),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_sta",
    network.wait_for_sta(ssid, psk, 10),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_ap",
    network.wait_for_ap(option.Some("ap"), option.None, 10),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_ap_timeout",
    network.wait_for_ap_timeout(10),
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "network.stop",
    network.stop(),
    network_runtime,
    network.error_to_string,
  ))
  Ok(Nil)
}
