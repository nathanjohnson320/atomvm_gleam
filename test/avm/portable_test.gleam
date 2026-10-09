//// Portable suite: platform, console; crypto/json deferred to full suites.

import atomvm_gleam/atomvm
import atomvm_gleam/console
import avm/check.{type Failure}
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  use _ <- result.try(platform_smoke())
  use _ <- result.try(random_smoke())
  use _ <- result.try(console_smoke())
  Ok(Nil)
}

fn platform_smoke() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.GenericUnix
    | atomvm.Emscripten
    | atomvm.Esp32
    | atomvm.Pico
    | atomvm.Stm32 -> check.cover("atomvm.platform", check.ok())
  }
}

fn random_smoke() -> Result(Nil, Failure) {
  // atomvm:random/0 may be undef on some unix builds — catch via FFI.
  case try_random() {
    Ok(n) -> {
      use _ <- result.try(check.cover("atomvm.random", check.ok()))
      check.assert_true("random non-neg", n >= 0)
    }
    Error(_) -> check.cover_not_supported("atomvm.random")
  }
}

fn console_smoke() -> Result(Nil, Failure) {
  use _ <- result.try(check.cover_ok(
    "console.print",
    console.print("avm_gleam portable ok\n"),
  ))
  use _ <- result.try(check.cover_ok(
    "console.print_err",
    console.print_err("avm_gleam portable err\n"),
  ))
  use _ <- result.try(check.cover_ok("console.flush", console.flush()))
  Ok(Nil)
}

@external(erlang, "avm_test_env_ffi", "try_random")
fn try_random() -> Result(Int, Nil)
