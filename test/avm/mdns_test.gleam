//// mDNS serialize/parse helpers - pure Erlang in atomvmlib / MCU firmware;
//// must Ok on unix + MCU. Emscripten: no-op.

import atomvm_gleam/atomvm
import atomvm_gleam/mdns
import avm/check.{type Failure}
import avm/expect
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    atomvm.GenericUnix | atomvm.Esp32 | atomvm.Pico | atomvm.Stm32 ->
      mdns_helpers_owned()
  }
}

fn mdns_helpers_owned() -> Result(Nil, Failure) {
  use wire <- result.try(expect.must_ok_value(
    "mdns.serialize_dns_name",
    mdns.serialize_dns_name([<<"a">>, <<"local">>]),
    mdns.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "mdns.parse_dns_name",
    mdns.parse_dns_name(wire, wire),
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
  use _ <- result.try(expect.must_ok(
    "mdns.serialize_dns_message",
    mdns.serialize_dns_message(msg),
    mdns.error_to_string,
  ))
  case mdns.parse_dns_message(<<>>) {
    Ok(_) | Error(_) -> check.cover("mdns.parse_dns_message", check.ok())
  }
}
