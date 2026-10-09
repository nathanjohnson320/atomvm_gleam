//// I2C open + transfer ops (Ok-or-soft-fail when no slave).

import atomvm_gleam/atomvm
import atomvm_gleam/i2c
import avm/check.{type Failure}
import avm/expect
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    _ -> i2c_ops_when_open()
  }
}

fn i2c_soft(e: i2c.Error) -> Bool {
  // No slave on QEMU — ESP_FAIL / timeout / badarg are expected.
  case e {
    i2c.NotSupported | i2c.Failed | i2c.Badarg | i2c.Timeout | i2c.Other(_) ->
      True
  }
}

fn i2c_ops_when_open() -> Result(Nil, Failure) {
  use bus_r <- result.try(expect.ok_value_or_not_supported(
    "i2c.open",
    i2c.open(i2c.Config(scl: 22, sda: 21, clock_speed_hz: 100_000)),
    i2c_soft,
    i2c.error_to_string,
  ))
  case bus_r {
    Error(Nil) -> {
      use _ <- result.try(check.cover_not_supported("i2c.begin_transmission"))
      use _ <- result.try(check.cover_not_supported("i2c.write_byte"))
      use _ <- result.try(check.cover_not_supported(
        "i2c.write_transmission_bytes",
      ))
      use _ <- result.try(check.cover_not_supported("i2c.end_transmission"))
      use _ <- result.try(check.cover_not_supported("i2c.read_bytes"))
      use _ <- result.try(check.cover_not_supported("i2c.write_bytes_to"))
      use _ <- result.try(check.cover_not_supported("i2c.write_bytes"))
      Ok(Nil)
    }
    Ok(bus) -> {
      use _ <- result.try(expect.ok_or_not_supported(
        "i2c.begin_transmission",
        i2c.begin_transmission(bus, 0x50),
        i2c_soft,
        i2c.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "i2c.write_byte",
        i2c.write_byte(bus, 0),
        i2c_soft,
        i2c.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "i2c.write_transmission_bytes",
        i2c.write_transmission_bytes(bus, <<0>>),
        i2c_soft,
        i2c.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "i2c.end_transmission",
        i2c.end_transmission(bus),
        i2c_soft,
        i2c.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "i2c.read_bytes",
        i2c.read_bytes(bus, 0x50, 0, 1),
        i2c_soft,
        i2c.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "i2c.write_bytes_to",
        i2c.write_bytes_to(bus, 0x50, <<0>>),
        i2c_soft,
        i2c.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "i2c.write_bytes",
        i2c.write_bytes(bus, 0x50, 0, <<0>>),
        i2c_soft,
        i2c.error_to_string,
      ))
      use _ <- result.try(check.cover_ok("i2c.close", i2c.close(bus)))
      Ok(Nil)
    }
  }
}
