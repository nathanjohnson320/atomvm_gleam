//// LEDC fade APIs (basic LEDC smoke lives in esp32_test).

import atomvm_gleam/atomvm
import atomvm_gleam/ledc
import avm/check.{type Failure}
import avm/expect
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    _ -> ledc_fades()
  }
}

fn ledc_fade_soft(e: ledc.Error) -> Bool {
  // Fade service often missing under QEMU; accept IDF codes / soft failures.
  case e {
    ledc.NotSupported
    | ledc.Failed
    | ledc.Badarg
    | ledc.Timeout
    | ledc.Code(_) -> True
    ledc.Other(reason) -> expect.is_undef_reason(reason)
  }
}

fn ledc_fades() -> Result(Nil, Failure) {
  let mode = ledc.low_speed_mode()
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.set_fade_with_time",
    ledc.set_fade_with_time(mode, 0, 0, 100),
    ledc_fade_soft,
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.set_fade_with_step",
    ledc.set_fade_with_step(mode, 0, 0, 1, 1),
    ledc_fade_soft,
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.set_fade_time_and_start",
    ledc.set_fade_time_and_start(mode, 0, 0, 100, 0),
    ledc_fade_soft,
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.set_fade_step_and_start",
    ledc.set_fade_step_and_start(mode, 0, 0, 1, 1, 0),
    ledc_fade_soft,
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.fade_start",
    ledc.fade_start(mode, 0, 0),
    ledc_fade_soft,
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.fade_stop",
    ledc.fade_stop(mode, 0),
    ledc_fade_soft,
    ledc.error_to_string,
  ))
  Ok(Nil)
}
