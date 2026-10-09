//// mDNS serialize/parse helpers.

import atomvm_gleam/atomvm
import atomvm_gleam/mdns
import avm/check.{type Failure}
import avm/expect
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    _ -> mdns_helpers()
  }
}

fn mdns_helpers() -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_not_supported(
    "mdns.serialize_dns_name",
    mdns.serialize_dns_name([<<"a">>, <<"local">>]),
    fn(e) {
      case e {
        mdns.NotSupported -> True
        mdns.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    mdns.error_to_string,
  ))
  use wire <- result.try(case mdns.serialize_dns_name([<<"a">>, <<"local">>]) {
    Ok(bytes) -> Ok(bytes)
    Error(_) -> Ok(<<0>>)
  })
  use _ <- result.try(expect.ok_or_not_supported(
    "mdns.parse_dns_name",
    mdns.parse_dns_name(wire, wire),
    fn(e) {
      case e {
        mdns.NotSupported -> True
        mdns.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    mdns.error_to_string,
  ))
  let msg =
    mdns.DnsMessage(
      id: 1,
      qr: 0,
      opcode: 0,
      aa: 0,
      questions: [],
      answers: [],
      authority_rr: [],
      additional_rr: [],
    )
  use _ <- result.try(expect.ok_or_not_supported(
    "mdns.serialize_dns_message",
    mdns.serialize_dns_message(msg),
    fn(e) {
      case e {
        mdns.NotSupported -> True
        mdns.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    mdns.error_to_string,
  ))
  use _ <- result.try(case mdns.parse_dns_message(<<>>) {
    Ok(_) | Error(_) -> check.cover("mdns.parse_dns_message", check.ok())
  })
  // mdns.start_link opens UDP and can crash the VM off-ESP — ESP32 only.
  Ok(Nil)
}
