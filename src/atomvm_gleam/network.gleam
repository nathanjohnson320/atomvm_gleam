/// Wi-Fi and SNTP wrappers for AtomVM's `network` module (0.7 managed STA).
///
/// Prefer the [Network Programming Guide (0.7)](https://doc.atomvm.org/release-0.7/network-programming-guide.html)
/// — especially [managed mode](https://doc.atomvm.org/release-0.7/network-programming-guide.html#managed-mode),
/// [`sta_connect`](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sta-connect),
/// [`wifi_scan`](https://doc.atomvm.org/release-0.7/network-programming-guide.html#wifi-scan), and
/// [SNTP](https://doc.atomvm.org/release-0.7/network-programming-guide.html#sntp-support).
///
/// Source: [`network.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/network.erl).
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

/// STA options for [`start`](#start).
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

/// SNTP options for [`start`](#start).
///
/// On sync, `notify` receives `{synchronized, {Sec, Usec}}`.
pub type SntpConfig {
  SntpConfig(host: String, notify: Pid)
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

/// Start the network interface (STA + optional SNTP).
///
/// See [`network:start/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/network.html#start-1)
/// and the [0.7 guide](https://doc.atomvm.org/release-0.7/network-programming-guide.html).
pub fn start(
  sta: StaConfig,
  sntp: Option(SntpConfig),
) -> Result(Nil, Error) {
  let StaConfig(managed:, ssid:, psk:, dhcp_hostname:, notify:) = sta
  case sntp {
    option.None ->
      start_ffi(managed, ssid, psk, dhcp_hostname, notify, False, "", notify)
    option.Some(SntpConfig(host:, notify: sntp_notify)) ->
      start_ffi(
        managed,
        ssid,
        psk,
        dhcp_hostname,
        notify,
        True,
        host,
        sntp_notify,
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
@external(erlang, "atomvm_gleam_network_ffi", "sta_disconnect")
pub fn sta_disconnect() -> Result(Nil, Error)

/// Start an async Wi-Fi scan (requires `scan_done` → `notify` from [`start`](#start)).
///
/// Results arrive as `{scan_results, …}` on the notify pid.
///
/// See [wifi_scan](https://doc.atomvm.org/release-0.7/network-programming-guide.html#wifi-scan).
@external(erlang, "atomvm_gleam_network_ffi", "wifi_scan")
pub fn wifi_scan(results: Int) -> Result(Nil, Error)

/// Blocking convenience: start STA, wait for DHCP, return `IpInfo`.
///
/// Useful for simple apps; badge-style UIs should prefer [`start`](#start) +
/// event messages.
///
/// See [`network:wait_for_sta/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/network.html#wait-for-sta-2).
@external(erlang, "atomvm_gleam_network_ffi", "wait_for_sta")
pub fn wait_for_sta(
  ssid: String,
  psk: String,
  timeout_ms: Int,
) -> Result(IpInfo, Error)

/// Stop the network interface.
@external(erlang, "atomvm_gleam_network_ffi", "stop")
pub fn stop() -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_network_ffi", "start")
fn start_ffi(
  managed: Bool,
  ssid: Option(String),
  psk: Option(String),
  dhcp_hostname: Option(String),
  notify: Pid,
  sntp_enabled: Bool,
  sntp_host: String,
  sntp_notify: Pid,
) -> Result(Nil, Error)
