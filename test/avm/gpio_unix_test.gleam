//// GPIO on generic UNIX via a stub sysfs tree.

import atomvm_gleam/atomvm
import atomvm_gleam/gpio
import avm/check.{type Failure}
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  let pin_n = 18
  let pin = gpio.pin(pin_n)
  let base = "/tmp/atomvm_gleam_gpio_sysfs"
  let pin_dir = base <> "/gpio" <> int_to_string(pin_n)

  use _ <- result.try(ensure_sysfs_stub(base, pin_dir))
  use _ <- result.try(check.cover_ok(
    "gpio.set_sysfs_base",
    gpio.set_sysfs_base(base),
  ))
  use _ <- result.try(check.cover_ok(
    "gpio.set_pin_mode",
    gpio.set_pin_mode(pin, gpio.Output),
  ))
  use _ <- result.try(check.cover_ok(
    "gpio.digital_write",
    gpio.digital_write(pin, gpio.PinHigh),
  ))
  use level_high <- result.try(check.cover_ok(
    "gpio.digital_read",
    gpio.digital_read(pin),
  ))
  use _ <- result.try(check.assert_eq("level high", level_high, gpio.PinHigh))
  use _ <- result.try(check.cover_ok(
    "gpio.digital_write",
    gpio.digital_write(pin, gpio.PinLow),
  ))
  use level_low <- result.try(check.assert_ok(
    "gpio.digital_read low",
    gpio.digital_read(pin),
  ))
  use _ <- result.try(check.assert_eq("level low", level_low, gpio.PinLow))
  use _ <- result.try(check.cover_ok("gpio.deinit", gpio.deinit(pin)))
  use _ <- result.try(check.cover_ok("gpio.init", gpio.init(pin)))
  use _ <- result.try(check.cover_ok("gpio.deinit", gpio.deinit(pin)))
  Ok(Nil)
}

fn ensure_sysfs_stub(base: String, pin_dir: String) -> Result(Nil, Failure) {
  let _ = atomvm.posix_unlink(pin_dir <> "/direction")
  let _ = atomvm.posix_unlink(pin_dir <> "/value")
  let _ = atomvm.posix_rmdir(pin_dir)
  let _ = atomvm.posix_unlink(base <> "/export")
  let _ = atomvm.posix_unlink(base <> "/unexport")
  let _ = atomvm.posix_rmdir(base)

  use _ <- result.try(mkdir_ok(base))
  use _ <- result.try(mkdir_ok(pin_dir))
  use _ <- result.try(write_file(base <> "/export", <<>>))
  use _ <- result.try(write_file(base <> "/unexport", <<>>))
  use _ <- result.try(write_file(pin_dir <> "/direction", <<"in">>))
  use _ <- result.try(write_file(pin_dir <> "/value", <<"0">>))
  Ok(Nil)
}

fn mkdir_ok(path: String) -> Result(Nil, Failure) {
  case atomvm.posix_mkdir(path, 0o755) {
    Ok(Nil) -> check.ok()
    Error(atomvm.Other("eexist")) -> check.ok()
    Error(reason) ->
      check.fail("mkdir " <> path <> ": " <> atomvm.error_to_string(reason))
  }
}

fn write_file(path: String, data: BitArray) -> Result(Nil, Failure) {
  use fd <- result.try(check.assert_ok(
    "posix_open " <> path,
    atomvm.posix_open_mode(
      path,
      [atomvm.OCreat, atomvm.OWronly, atomvm.OTrunc],
      0o644,
    ),
  ))
  use _ <- result.try(case data {
    <<>> -> check.ok()
    _ -> {
      use _ <- result.try(check.assert_ok(
        "posix_write " <> path,
        atomvm.posix_write(fd, data),
      ))
      check.ok()
    }
  })
  check.assert_ok("posix_close " <> path, atomvm.posix_close(fd))
}

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(n: Int) -> String
