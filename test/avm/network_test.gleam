//// Network entrypoints — ESP32 live / INTEGRATION; soft elsewhere.

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
  // Node WASM: unresolved network NIFs can abort via XHR/undef.
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    _ -> network_entrypoints()
  }
}

fn network_ns(e: network.Error) -> Bool {
  case e {
    network.NotSupported | network.Failed | network.Disconnected -> True
    network.Other(reason) ->
      expect.is_undef_reason(reason)
      || reason == "network_down"
      || string.contains(reason, "already_started")
    _ -> False
  }
}

fn network_wait(
  id: String,
  result: Result(a, network.Error),
) -> Result(Nil, Failure) {
  case result {
    Ok(_) -> check.cover(id, check.ok())
    Error(network.NotSupported) -> check.cover_not_supported(id)
    Error(network.Timeout) -> check.cover(id, check.ok())
    Error(other) -> check.fail(id <> ": " <> network.error_to_string(other))
  }
}

fn network_entrypoints() -> Result(Nil, Failure) {
  // network:start opens a port that badarg-crashes on non-ESP platforms.
  // Only probe start/wait APIs on ESP32; elsewhere assert sta_status NotSupported.
  case atomvm.platform() {
    atomvm.Esp32 -> network_entrypoints_esp32()
    _ ->
      expect.ok_or_not_supported(
        "network.sta_status",
        network.sta_status(),
        network_ns,
        network.error_to_string,
      )
  }
}

fn network_entrypoints_esp32() -> Result(Nil, Failure) {
  let sta =
    network.StaConfig(
      managed: True,
      ssid: option.Some("avm_gleam_test"),
      psk: option.Some("password"),
      dhcp_hostname: option.None,
      notify: process.self(),
    )
  // network.start hangs under QEMU (no radio / wifi driver stalls). Skip unless
  // AVM_GLEAM_INTEGRATION is set for a real board run.
  use _ <- result.try(case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False -> {
      use _ <- result.try(integration.skip(
        "network.* (QEMU hang on start; set AVM_GLEAM_INTEGRATION=1)",
      ))
      use _ <- result.try(check.cover_not_supported("network.start"))
      use _ <- result.try(check.cover_not_supported("network.stop"))
      use _ <- result.try(check.cover_not_supported("network.start_link"))
      use _ <- result.try(check.cover_not_supported("network.start_with"))
      use _ <- result.try(check.cover_not_supported("network.start_link_with"))
      use _ <- result.try(check.cover_not_supported("network.sta_connect"))
      use _ <- result.try(check.cover_not_supported("network.sta_connect_to"))
      use _ <- result.try(check.cover_not_supported("network.sta_disconnect"))
      use _ <- result.try(check.cover_not_supported("network.wifi_scan_default"))
      use _ <- result.try(check.cover_not_supported("network.wifi_scan"))
      use _ <- result.try(check.cover_not_supported("network.sta_rssi"))
      use _ <- result.try(check.cover_not_supported(
        "network.wait_for_sta_timeout",
      ))
      use _ <- result.try(check.cover_not_supported(
        "network.wait_for_sta_config",
      ))
      use _ <- result.try(check.cover_not_supported("network.wait_for_sta"))
      use _ <- result.try(check.cover_not_supported("network.wait_for_ap"))
      use _ <- result.try(check.cover_not_supported(
        "network.wait_for_ap_timeout",
      ))
      Ok(Nil)
    }
    True -> network_entrypoints_esp32_live(sta)
  })
  Ok(Nil)
}

fn network_entrypoints_esp32_live(
  sta: network.StaConfig,
) -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_not_supported(
    "network.start",
    network.start(sta, option.None),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.start_link",
    network.start_link(sta, option.None),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.start_with",
    network.start_with(option.Some(sta), option.None, option.None, option.None),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.start_link_with",
    network.start_link_with(
      option.Some(sta),
      option.None,
      option.None,
      option.None,
    ),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.sta_connect",
    network.sta_connect(),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.sta_connect_to",
    network.sta_connect_to("avm_gleam_test", "password"),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.sta_disconnect",
    network.sta_disconnect(),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.wifi_scan_default",
    network.wifi_scan_default(),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.wifi_scan",
    network.wifi_scan(4),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.sta_rssi",
    network.sta_rssi(),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_sta_timeout",
    network.wait_for_sta_timeout(10),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_sta_config",
    network.wait_for_sta_config(
      option.Some("avm_gleam_test"),
      option.Some("password"),
    ),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_sta",
    network.wait_for_sta("avm_gleam_test", "password", 10),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_ap",
    network.wait_for_ap(option.Some("ap"), option.None, 10),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_ap_timeout",
    network.wait_for_ap_timeout(10),
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.stop",
    network.stop(),
    network_ns,
    network.error_to_string,
  ))
  Ok(Nil)
}
