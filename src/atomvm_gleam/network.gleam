/// Wi-Fi, AP, SNTP, and mDNS config wrappers for AtomVM's `network` module (0.7).
///
/// Prefer the [Network Programming Guide (0.7)](https://doc.atomvm.org/release-0.7/network-programming-guide.html)
/// - especially [managed mode](https://doc.atomvm.org/release-0.7/network-programming-guide.html#managed-mode),
/// [AP mode](https://doc.atomvm.org/release-0.7/network-programming-guide.html#ap-mode),
/// [`sta_connect`](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-connect),
/// [`wifi_scan`](https://doc.atomvm.org/release-0.7/network-programming-guide.html#wifi-scan),
/// [`sta_rssi`](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-rssi),
/// [`sta_status`](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-status), and
/// [SNTP](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sntp-support).
///
/// Source: [`network.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/network.erl).
///
/// mDNS here is **config plumbing** on `network:start/1` /
/// `network:start_link/1` only (`{mdns, [{host, …}, {ttl, …}]}`).
/// For the standalone responder, see [`atomvm_gleam/mdns`](atomvm_gleam/mdns.html).
import gleam/erlang/process.{type Pid}
import gleam/option.{type Option}

/// Errors from the network driver.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Disconnected
  Other(String)
}

/// IPv4 address as four octets.
pub type Ipv4Address {
  Ipv4Address(a: Int, b: Int, c: Int, d: Int)
}

/// Address / netmask / gateway triple from DHCP (`got_ip` / `wait_for_sta`).
pub type IpInfo {
  IpInfo(address: Ipv4Address, netmask: Ipv4Address, gateway: Ipv4Address)
}

/// STA connection status from [`sta_status`](#sta_status).
///
/// Prefixed constructors avoid clashing with [`Error`](#Error) variants;
/// FFI maps AtomVM atoms (`associated`, `connected`, …) to these values.
pub type StaStatus {
  StaAssociated
  StaConnected
  StaConnecting
  StaDegraded
  StaDisconnected
  StaDisconnecting
  StaInactive
}

/// STA options for [`start`](#start) / [`start_with`](#start_with).
///
/// When `managed` is `True`, the radio starts without joining until
/// [`sta_connect`](#sta_connect) / [`sta_connect_to`](#sta_connect_to).
///
/// Event callbacks send these messages to `notify`:
/// - `connected`
/// - `{got_ip, IpInfo}` (Erlang `{IP, Netmask, Gateway}` tuples)
/// - `disconnected`
/// - `{scan_results, Results}` when `scan_done` is wired to `notify`
pub type StaConfig {
  StaConfig(
    managed: Bool,
    ssid: Option(String),
    psk: Option(String),
    dhcp_hostname: Option(String),
    notify: Pid,
  )
}

/// SoftAP options for [`start_with`](#start_with).
///
/// Event callbacks send these messages to `notify`:
/// - `ap_started`
/// - `{sta_connected, Mac}` (6-byte MAC binary)
/// - `{sta_disconnected, Mac}`
/// - `{sta_ip_assigned, Address}` (Erlang `{A, B, C, D}`)
pub type ApConfig {
  ApConfig(
    ssid: Option(String),
    psk: Option(String),
    ap_channel: Option(Int),
    ap_ssid_hidden: Option(Bool),
    ap_max_connections: Option(Int),
    notify: Pid,
  )
}

/// SNTP options for [`start`](#start) / [`start_with`](#start_with).
///
/// On sync, `notify` receives `{synchronized, {Sec, Usec}}`.
pub type SntpConfig {
  SntpConfig(host: String, notify: Pid)
}

/// mDNS options passed through `network:start/1` as `{mdns, […]}`.
///
/// `ttl` is optional; omit to use the AtomVM default.
pub type MdnsConfig {
  MdnsConfig(host: String, ttl: Option(Int))
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    Disconnected -> "disconnected"
    Other(reason) -> reason
  }
}

/// Format a [`StaStatus`](#StaStatus) for logging.
pub fn sta_status_to_string(status: StaStatus) -> String {
  case status {
    StaAssociated -> "associated"
    StaConnected -> "connected"
    StaConnecting -> "connecting"
    StaDegraded -> "degraded"
    StaDisconnected -> "disconnected"
    StaDisconnecting -> "disconnecting"
    StaInactive -> "inactive"
  }
}

/// Start the network interface (STA + optional SNTP).
///
/// Compatibility wrapper around [`start_with`](#start_with) with no AP or mDNS.
///
/// See [`network.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/network.erl)
/// and the [0.7 guide](https://doc.atomvm.org/release-0.7/network-programming-guide.html).
pub fn start(sta: StaConfig, sntp: Option(SntpConfig)) -> Result(Nil, Error) {
  start_with(option.Some(sta), option.None, sntp, option.None)
}

/// Start and link the network interface (STA + optional SNTP).
///
/// Same config as [`start`](#start), but the network gen_server is linked to
/// the caller (`network:start_link/1`).
///
/// See [`network.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/network.erl)
/// and the [0.7 guide](https://doc.atomvm.org/release-0.7/network-programming-guide.html).
pub fn start_link(
  sta: StaConfig,
  sntp: Option(SntpConfig),
) -> Result(Nil, Error) {
  start_link_with(option.Some(sta), option.None, sntp, option.None)
}

/// Start the network with optional STA, AP, SNTP, and mDNS sections.
///
/// At least one of `sta` or `ap` should be provided. STA+AP is supported.
///
/// See [AP mode](https://doc.atomvm.org/release-0.7/network-programming-guide.html#ap-mode)
/// and [STA+AP mode](https://doc.atomvm.org/release-0.7/network-programming-guide.html#staap-mode).
pub fn start_with(
  sta: Option(StaConfig),
  ap: Option(ApConfig),
  sntp: Option(SntpConfig),
  mdns: Option(MdnsConfig),
) -> Result(Nil, Error) {
  do_start(sta, ap, sntp, mdns, False)
}

/// Start and link the network with optional STA, AP, SNTP, and mDNS sections.
///
/// Same config as [`start_with`](#start_with), but linked to the caller
/// (`network:start_link/1`).
///
/// See [`network.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/network.erl).
pub fn start_link_with(
  sta: Option(StaConfig),
  ap: Option(ApConfig),
  sntp: Option(SntpConfig),
  mdns: Option(MdnsConfig),
) -> Result(Nil, Error) {
  do_start(sta, ap, sntp, mdns, True)
}

fn do_start(
  sta: Option(StaConfig),
  ap: Option(ApConfig),
  sntp: Option(SntpConfig),
  mdns: Option(MdnsConfig),
  linked: Bool,
) -> Result(Nil, Error) {
  let #(sta_enabled, managed, ssid, psk, dhcp_hostname, sta_notify) = case sta {
    option.None -> #(
      False,
      False,
      option.None,
      option.None,
      option.None,
      process.self(),
    )
    option.Some(StaConfig(managed:, ssid:, psk:, dhcp_hostname:, notify:)) -> #(
      True,
      managed,
      ssid,
      psk,
      dhcp_hostname,
      notify,
    )
  }
  let #(
    ap_enabled,
    ap_ssid,
    ap_psk,
    ap_channel,
    ap_ssid_hidden,
    ap_max_connections,
    ap_notify,
  ) = case ap {
    option.None -> #(
      False,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      process.self(),
    )
    option.Some(ApConfig(
      ssid:,
      psk:,
      ap_channel:,
      ap_ssid_hidden:,
      ap_max_connections:,
      notify:,
    )) -> #(
      True,
      ssid,
      psk,
      ap_channel,
      ap_ssid_hidden,
      ap_max_connections,
      notify,
    )
  }
  let #(sntp_enabled, sntp_host, sntp_notify) = case sntp {
    option.None -> #(False, "", process.self())
    option.Some(SntpConfig(host:, notify:)) -> #(True, host, notify)
  }
  let #(mdns_enabled, mdns_host, mdns_ttl) = case mdns {
    option.None -> #(False, "", option.None)
    option.Some(MdnsConfig(host:, ttl:)) -> #(True, host, ttl)
  }
  case linked {
    True ->
      start_link_ffi(
        sta_enabled,
        managed,
        ssid,
        psk,
        dhcp_hostname,
        sta_notify,
        ap_enabled,
        ap_ssid,
        ap_psk,
        ap_channel,
        ap_ssid_hidden,
        ap_max_connections,
        ap_notify,
        sntp_enabled,
        sntp_host,
        sntp_notify,
        mdns_enabled,
        mdns_host,
        mdns_ttl,
      )
    False ->
      start_ffi(
        sta_enabled,
        managed,
        ssid,
        psk,
        dhcp_hostname,
        sta_notify,
        ap_enabled,
        ap_ssid,
        ap_psk,
        ap_channel,
        ap_ssid_hidden,
        ap_max_connections,
        ap_notify,
        sntp_enabled,
        sntp_host,
        sntp_notify,
        mdns_enabled,
        mdns_host,
        mdns_ttl,
      )
  }
}

/// Connect using credentials from the last `start` / `sta_connect_to` config.
///
/// See [sta_connect](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-connect).
@external(erlang, "atomvm_gleam_network_ffi", "sta_connect")
pub fn sta_connect() -> Result(Nil, Error)

/// Connect to `ssid` with `psk` (empty string for open networks).
///
/// See [sta_connect](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-connect).
@external(erlang, "atomvm_gleam_network_ffi", "sta_connect_to")
pub fn sta_connect_to(ssid: String, psk: String) -> Result(Nil, Error)

/// Disconnect from the current access point.
///
/// See [sta_disconnect](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-disconnect).
@external(erlang, "atomvm_gleam_network_ffi", "sta_disconnect")
pub fn sta_disconnect() -> Result(Nil, Error)

/// Start a Wi-Fi scan with defaults from the running STA config (`network:wifi_scan/0`).
///
/// Uses `default_scan_results`, dwell, passive, and hidden settings from the last
/// `start` STA config when available. With `scan_done` → `notify`, results arrive
/// as `{scan_results, …}` on the notify pid.
///
/// See [wifi_scan](https://doc.atomvm.org/release-0.7/network-programming-guide.html#wifi-scan).
@external(erlang, "atomvm_gleam_network_ffi", "wifi_scan")
pub fn wifi_scan_default() -> Result(Nil, Error)

/// Start an async Wi-Fi scan requesting up to `results` APs (`network:wifi_scan/1`).
///
/// Requires `scan_done` → `notify` from [`start`](#start). Results arrive as
/// `{scan_results, …}` on the notify pid.
///
/// See [wifi_scan](https://doc.atomvm.org/release-0.7/network-programming-guide.html#wifi-scan).
@external(erlang, "atomvm_gleam_network_ffi", "wifi_scan")
pub fn wifi_scan(results: Int) -> Result(Nil, Error)

/// RSSI of the associated AP in dBm (`{ok, Dbm}`).
///
/// See [`sta_rssi`](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-rssi).
@external(erlang, "atomvm_gleam_network_ffi", "sta_rssi")
pub fn sta_rssi() -> Result(Int, Error)

/// Current STA interface status.
///
/// See [`sta_status`](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-status).
@external(erlang, "atomvm_gleam_network_ffi", "sta_status")
pub fn sta_status() -> Result(StaStatus, Error)

/// Blocking convenience: start STA with empty config and default 15_000 ms timeout
/// (`network:wait_for_sta/0`).
///
/// Useful for simple apps; badge-style UIs should prefer [`start`](#start) +
/// event messages.
///
/// See [STA Mode Convenience Functions](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-mode-convenience-functions).
@external(erlang, "atomvm_gleam_network_ffi", "wait_for_sta_default")
pub fn wait_for_sta_default() -> Result(IpInfo, Error)

/// Blocking convenience: start STA with empty config and `timeout_ms`
/// (`network:wait_for_sta/1` timeout clause).
///
/// See [STA Mode Convenience Functions](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-mode-convenience-functions).
@external(erlang, "atomvm_gleam_network_ffi", "wait_for_sta_timeout")
pub fn wait_for_sta_timeout(timeout_ms: Int) -> Result(IpInfo, Error)

/// Blocking convenience: start STA with optional credentials and default 15_000 ms
/// timeout (`network:wait_for_sta/1` config clause).
///
/// Omit `ssid` / `psk` (`None`) for an empty STA property list (NVS / last config).
///
/// See [STA Mode Convenience Functions](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-mode-convenience-functions).
@external(erlang, "atomvm_gleam_network_ffi", "wait_for_sta_config")
pub fn wait_for_sta_config(
  ssid: Option(String),
  psk: Option(String),
) -> Result(IpInfo, Error)

/// Blocking convenience: start STA with `ssid`/`psk` and wait for DHCP
/// (`network:wait_for_sta/2`).
///
/// Useful for simple apps; badge-style UIs should prefer [`start`](#start) +
/// event messages.
///
/// See [STA Mode Convenience Functions](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-mode-convenience-functions).
@external(erlang, "atomvm_gleam_network_ffi", "wait_for_sta")
pub fn wait_for_sta(
  ssid: String,
  psk: String,
  timeout_ms: Int,
) -> Result(IpInfo, Error)

/// Blocking convenience: start AP and wait until ready (`network:wait_for_ap/2`).
///
/// Omit `ssid` / `psk` (`None`) to use AtomVM defaults (generated SSID / open AP).
///
/// See [AP Mode Convenience Functions](https://doc.atomvm.org/release-0.7/network-programming-guide.html#ap-mode-convenience-functions).
@external(erlang, "atomvm_gleam_network_ffi", "wait_for_ap")
pub fn wait_for_ap(
  ssid: Option(String),
  psk: Option(String),
  timeout_ms: Int,
) -> Result(Nil, Error)

/// Equivalent to `wait_for_ap(None, None, timeout_ms)` (`network:wait_for_ap/1`
/// timeout clause).
pub fn wait_for_ap_timeout(timeout_ms: Int) -> Result(Nil, Error) {
  wait_for_ap(option.None, option.None, timeout_ms)
}

/// Start AP with empty config and default 15_000 ms timeout (`network:wait_for_ap/0`).
///
/// See [AP Mode Convenience Functions](https://doc.atomvm.org/release-0.7/network-programming-guide.html#ap-mode-convenience-functions).
@external(erlang, "atomvm_gleam_network_ffi", "wait_for_ap_default")
pub fn wait_for_ap_default() -> Result(Nil, Error)

/// Stop the network interface.
///
/// See [Stopping the Network](https://doc.atomvm.org/release-0.7/network-programming-guide.html#stopping-the-network).
@external(erlang, "atomvm_gleam_network_ffi", "stop")
pub fn stop() -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_network_ffi", "start")
fn start_ffi(
  sta_enabled: Bool,
  managed: Bool,
  ssid: Option(String),
  psk: Option(String),
  dhcp_hostname: Option(String),
  sta_notify: Pid,
  ap_enabled: Bool,
  ap_ssid: Option(String),
  ap_psk: Option(String),
  ap_channel: Option(Int),
  ap_ssid_hidden: Option(Bool),
  ap_max_connections: Option(Int),
  ap_notify: Pid,
  sntp_enabled: Bool,
  sntp_host: String,
  sntp_notify: Pid,
  mdns_enabled: Bool,
  mdns_host: String,
  mdns_ttl: Option(Int),
) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_network_ffi", "start_link")
fn start_link_ffi(
  sta_enabled: Bool,
  managed: Bool,
  ssid: Option(String),
  psk: Option(String),
  dhcp_hostname: Option(String),
  sta_notify: Pid,
  ap_enabled: Bool,
  ap_ssid: Option(String),
  ap_psk: Option(String),
  ap_channel: Option(Int),
  ap_ssid_hidden: Option(Bool),
  ap_max_connections: Option(Int),
  ap_notify: Pid,
  sntp_enabled: Bool,
  sntp_host: String,
  sntp_notify: Pid,
  mdns_enabled: Bool,
  mdns_host: String,
  mdns_ttl: Option(Int),
) -> Result(Nil, Error)
