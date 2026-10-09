//// avm_pubsub start/sub/pub/unsub (generic_unix and other OTP-capable targets).

import atomvm_gleam/avm_pubsub
import avm/check.{type Failure}
import gleam/erlang/process
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  use server <- result.try(check.cover_ok(
    "avm_pubsub.start",
    avm_pubsub.start(),
  ))
  use _ <- result.try(check.cover_ok(
    "avm_pubsub.sub",
    avm_pubsub.sub(server, "topic"),
  ))
  use n <- result.try(check.cover_ok(
    "avm_pubsub.publish",
    avm_pubsub.publish(server, "topic", "hello"),
  ))
  use _ <- result.try(check.assert_true("pubsub notified >= 0", n >= 0))
  use _ <- result.try(check.cover_ok(
    "avm_pubsub.unsub",
    avm_pubsub.unsub(server, "topic"),
  ))
  use named <- result.try(check.cover_ok(
    "avm_pubsub.start_named",
    avm_pubsub.start_named("avm_gleam_pubsub_test"),
  ))
  use _ <- result.try(check.cover_ok(
    "avm_pubsub.sub_pid",
    avm_pubsub.sub_pid(named, "t2", process.self()),
  ))
  use _ <- result.try(check.cover_ok(
    "avm_pubsub.unsub_pid",
    avm_pubsub.unsub_pid(named, "t2", process.self()),
  ))
  Ok(Nil)
}
