/// Standalone mDNS responder wrapping AtomVM's `mdns` module (0.7).
///
/// Resolves `Hostname.local` for a given IPv4 interface. Prefer this over
/// network-driver mDNS config when you need an independent responder.
///
/// Source: [`mdns.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/mdns.erl).
import gleam/option.{type Option}

/// Opaque handle for a running mDNS gen_server (`pid()` from `mdns:start_link/1`).
pub type Server

/// Errors from the mDNS responder.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// IPv4 address as four octets (`inet:ip4_address()`).
pub type Ipv4Address {
  Ipv4Address(a: Int, b: Int, c: Int, d: Int)
}

/// Options for [`start_link`](#start_link).
///
/// - `hostname` — local name without `.local` (required)
/// - `interface` — IPv4 address of the interface to advertise (required)
/// - `ttl` — DNS TTL in seconds; omit for the upstream default (900)
///
/// See [`mdns:start_link/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/mdns.erl).
pub type Config {
  Config(hostname: String, interface: Ipv4Address, ttl: Option(Int))
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

/// Start an mDNS responder and resolve `hostname.local` on `interface`.
///
/// See [`mdns:start_link/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/mdns.erl).
pub fn start_link(config: Config) -> Result(Server, Error) {
  let Config(hostname:, interface:, ttl:) = config
  let Ipv4Address(a:, b:, c:, d:) = interface
  start_link_ffi(hostname, a, b, c, d, ttl)
}

/// Stop an mDNS responder started with [`start_link`](#start_link).
///
/// See [`mdns:stop/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/mdns.erl).
@external(erlang, "atomvm_gleam_mdns_ffi", "stop")
pub fn stop(server: Server) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_mdns_ffi", "start_link")
fn start_link_ffi(
  hostname: String,
  a: Int,
  b: Int,
  c: Int,
  d: Int,
  ttl: Option(Int),
) -> Result(Server, Error)
