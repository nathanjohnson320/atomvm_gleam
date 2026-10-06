/// Standalone mDNS responder wrapping AtomVM's `mdns` module (0.7).
///
/// Resolves `Hostname.local` for a given IPv4 interface. Prefer this over
/// network-driver mDNS config when you need an independent responder.
///
/// Also exposes DNS message / name **protocol helpers** (`parse_*` /
/// `serialize_*`) used by the upstream responder. These are separate from
/// the gen_server lifecycle (`start_link` / `stop`) and do not wrap
/// callbacks.
///
/// Source: [`mdns.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/mdns.erl).
import gleam/option.{type Option}

/// Opaque handle for a running mDNS gen_server (`pid()` from `mdns:start_link/1`).
pub type Server

/// Errors from the mDNS responder and DNS protocol helpers.
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

/// One DNS question (`#dns_question{}`).
///
/// `unicast_response` is the mDNS unicast-response bit (0 or 1) parsed from
/// the high bit of qclass on the wire.
pub type DnsQuestion {
  DnsQuestion(
    qname: List(BitArray),
    qtype: Int,
    unicast_response: Int,
    qclass: Int,
  )
}

/// One DNS resource record (`#dns_rrecord{}`).
///
/// `record_type` is upstream `type` (Gleam reserves `type` as a keyword).
pub type DnsRrecord {
  DnsRrecord(
    name: List(BitArray),
    record_type: Int,
    class: Int,
    ttl: Int,
    rdata: BitArray,
  )
}

/// Parsed / serializable DNS message (`#dns_message{}`).
///
/// Field order matches the upstream Erlang record so FFI can pass values
/// through without reshaping.
pub type DnsMessage {
  DnsMessage(
    id: Int,
    qr: Int,
    opcode: Int,
    aa: Int,
    questions: List(DnsQuestion),
    answers: List(DnsRrecord),
    authority_rr: List(DnsRrecord),
    additional_rr: List(DnsRrecord),
  )
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

/// Parse a DNS message binary into a [`DnsMessage`](#DnsMessage).
///
/// Protocol helper; not part of the responder lifecycle.
///
/// See [`mdns:parse_dns_message/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/mdns.erl).
@external(erlang, "atomvm_gleam_mdns_ffi", "parse_dns_message")
pub fn parse_dns_message(message: BitArray) -> Result(DnsMessage, Error)

/// Serialize a [`DnsMessage`](#DnsMessage) to a DNS wire binary.
///
/// Protocol helper; not part of the responder lifecycle.
///
/// See [`mdns:serialize_dns_message/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/mdns.erl).
@external(erlang, "atomvm_gleam_mdns_ffi", "serialize_dns_message")
pub fn serialize_dns_message(message: DnsMessage) -> Result(BitArray, Error)

/// Parse a DNS name from `data`, resolving compression pointers against
/// the full `message` binary. Returns labels and the remaining tail.
///
/// Protocol helper; not part of the responder lifecycle.
///
/// See [`mdns:parse_dns_name/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/mdns.erl).
@external(erlang, "atomvm_gleam_mdns_ffi", "parse_dns_name")
pub fn parse_dns_name(
  message: BitArray,
  data: BitArray,
) -> Result(#(List(BitArray), BitArray), Error)

/// Serialize DNS name labels to a wire binary (no compression).
///
/// Protocol helper; not part of the responder lifecycle.
///
/// See [`mdns:serialize_dns_name/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_network/src/mdns.erl).
@external(erlang, "atomvm_gleam_mdns_ffi", "serialize_dns_name")
pub fn serialize_dns_name(name: List(BitArray)) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_mdns_ffi", "start_link")
fn start_link_ffi(
  hostname: String,
  a: Int,
  b: Int,
  c: Int,
  d: Int,
  ttl: Option(Int),
) -> Result(Server, Error)
