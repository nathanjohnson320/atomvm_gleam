//// UART write/read loopback over a socat PTY pair (GenericUnix).
////
//// Mirrors AtomVM's `test_uart` harness: spawn socat, open both ends via
//// `uart.open`, write → read. Skips when socat / PTYs are unavailable.

import atomvm_gleam/uart
import avm/check.{type Failure, Failure}
import avm/integration
import gleam/option
import gleam/result

fn fail(message: String) -> Result(a, Failure) {
  Error(Failure(message))
}

pub fn run() -> Result(Nil, Failure) {
  case try_socat_ptys() {
    Error(reason) -> integration.skip("uart loopback: " <> reason)
    Ok(#(handle, pty_a, pty_b)) -> {
      let result = run_with_ptys(pty_a, pty_b)
      stop_socat(handle)
      result
    }
  }
}

fn run_with_ptys(pty_a: String, pty_b: String) -> Result(Nil, Failure) {
  let cfg = uart.Config(..uart.default_config(), speed: option.Some(115_200))
  use uart_a <- result.try(check.cover_ok("uart.open", uart.open(pty_a, cfg)))
  use uart_b <- result.try(case uart.open(pty_b, cfg) {
    Ok(u) -> Ok(u)
    Error(reason) -> {
      let _ = uart.close(uart_a)
      fail("uart.open B: " <> uart.error_to_string(reason))
    }
  })
  let outcome = {
    use _ <- result.try(check.cover_ok(
      "uart.write",
      uart.write(uart_a, <<"hello-gleam">>),
    ))
    use got <- result.try(check.cover_ok("uart.read", uart.read(uart_b, 2000)))
    use _ <- result.try(check.assert_eq("uart payload", got, <<"hello-gleam">>))
    use _ <- result.try(check.cover_ok(
      "uart.write",
      uart.write(uart_b, <<"pong">>),
    ))
    use got2 <- result.try(check.assert_ok(
      "uart.read back",
      uart.read(uart_a, 2000),
    ))
    use _ <- result.try(check.assert_eq("uart back", got2, <<"pong">>))
    use _ <- result.try(check.assert_error(
      "uart.read timeout",
      uart.read(uart_a, 100),
    ))
    Ok(Nil)
  }
  let _ = check.cover_ok("uart.close", uart.close(uart_a))
  let _ = uart.close(uart_b)
  // open_default is soft-covered elsewhere; tag here only if we exercised it.
  outcome
}

@external(erlang, "avm_test_env_ffi", "try_socat_ptys")
fn try_socat_ptys() -> Result(#(SocatHandle, String, String), String)

@external(erlang, "avm_test_env_ffi", "stop_socat")
fn stop_socat(handle: SocatHandle) -> Nil

type SocatHandle
