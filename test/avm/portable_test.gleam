//// Portable suite: platform, console, pack/priv helpers.

import atomvm_gleam/atomvm
import atomvm_gleam/console
import avm/check.{type Failure}
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  use _ <- result.try(platform_smoke())
  use _ <- result.try(random_smoke())
  use _ <- result.try(console_smoke())
  use _ <- result.try(console_extra())
  use _ <- result.try(pack_priv_and_clock())
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
    Ok(_n) -> check.cover("atomvm.random", check.ok())
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

fn console_extra() -> Result(Nil, Failure) {
  case console.start() {
    Ok(c) -> {
      use _ <- result.try(check.cover("console.start", check.ok()))
      use _ <- result.try(check.cover_ok("console.puts", console.puts("bulk\n")))
      use _ <- result.try(check.cover_ok(
        "console.puts_to",
        console.puts_to(c, "bulk2\n"),
      ))
      use _ <- result.try(check.cover_ok(
        "console.flush_handle",
        console.flush_handle(c),
      ))
      Ok(Nil)
    }
    Error(console.NotSupported) | Error(console.Badarg) -> {
      use _ <- result.try(check.cover("console.start", check.ok()))
      use _ <- result.try(check.cover_ok("console.puts", console.puts("bulk\n")))
      use _ <- result.try(check.cover_not_supported("console.puts_to"))
      use _ <- result.try(check.cover_not_supported("console.flush_handle"))
      Ok(Nil)
    }
    Error(other) ->
      check.fail("console.start: " <> console.error_to_string(other))
  }
}

fn pack_priv_and_clock() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.GenericUnix -> {
      // Missing pack: must Error (NotFound/Failed/Other), never Ok.
      use _ <- result.try(
        case atomvm.add_avm_pack_file("/nonexistent.avm", "x") {
          Error(_) -> check.cover("atomvm.add_avm_pack_file", check.ok())
          Ok(_) -> check.fail("add_avm_pack_file unexpectedly Ok")
        },
      )
      use _ <- result.try(case atomvm.read_priv("missing", "x") {
        Error(_) -> check.cover("atomvm.read_priv", check.ok())
        Ok(_) -> check.fail("read_priv unexpectedly Ok")
      })
      let _ = atomvm.read_priv_option("missing", "x")
      use _ <- result.try(check.cover("atomvm.read_priv_option", check.ok()))
      // Setting clock may be denied; Ok or Error both prove the NIF path.
      case atomvm.posix_clock_settime(atomvm.Realtime, #(0, 0)) {
        Ok(_) | Error(_) ->
          check.cover("atomvm.posix_clock_settime", check.ok())
      }
    }
    _ -> {
      use _ <- result.try(
        case atomvm.add_avm_pack_file("/nonexistent.avm", "x") {
          Error(atomvm.NotSupported) ->
            check.cover_not_supported("atomvm.add_avm_pack_file")
          Error(_) -> check.cover("atomvm.add_avm_pack_file", check.ok())
          Ok(_) -> check.fail("add_avm_pack_file Ok off unix")
        },
      )
      use _ <- result.try(case atomvm.read_priv("missing", "x") {
        Error(atomvm.NotSupported) ->
          check.cover_not_supported("atomvm.read_priv")
        Error(_) -> check.cover("atomvm.read_priv", check.ok())
        Ok(_) -> check.fail("read_priv Ok off unix")
      })
      let _ = atomvm.read_priv_option("missing", "x")
      use _ <- result.try(check.cover("atomvm.read_priv_option", check.ok()))
      use _ <- result.try(case atomvm.posix_mkfifo("/tmp/x", 0o644) {
        Error(atomvm.NotSupported) ->
          check.cover_not_supported("atomvm.posix_mkfifo")
        Error(_) -> check.cover("atomvm.posix_mkfifo", check.ok())
        Ok(_) -> check.ok()
      })
      use _ <- result.try(
        case atomvm.posix_clock_settime(atomvm.Realtime, #(0, 0)) {
          Error(atomvm.NotSupported) ->
            check.cover_not_supported("atomvm.posix_clock_settime")
          Ok(_) | Error(_) ->
            check.cover("atomvm.posix_clock_settime", check.ok())
        },
      )
      Ok(Nil)
    }
  }
}

@external(erlang, "avm_test_env_ffi", "try_random")
fn try_random() -> Result(Int, Nil)
