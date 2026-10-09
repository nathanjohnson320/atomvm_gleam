//// LEDC fade APIs - ESP32 owns LEDC. Fade calls can panic under QEMU
//// (LoadProhibited) - SKIP unless INTEGRATION. Off-platform: NotSupported.
//// Basic timer/channel smoke lives in `esp32_test` (hard Ok).

import atomvm_gleam/atomvm
import atomvm_gleam/ledc
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    atomvm.Esp32 -> ledc_fades_esp32()
    _ -> ledc_off_platform()
  }
}

fn ledc_ns(e: ledc.Error) -> Bool {
  case e {
    ledc.NotSupported -> True
    ledc.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
  }
}

fn ledc_runtime(e: ledc.Error) -> Bool {
  case e {
    ledc.NotSupported -> False
    _ -> True
  }
}

fn ledc_off_platform() -> Result(Nil, Failure) {
  expect.must_not_supported(
    "ledc.set_fade_with_time",
    ledc.set_fade_with_time(ledc.low_speed_mode(), 0, 0, 100),
    ledc_ns,
    ledc.error_to_string,
  )
}

fn ledc_fades_esp32() -> Result(Nil, Failure) {
  case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False ->
      integration.skip(
        "ledc fade APIs (QEMU LoadProhibited; set AVM_GLEAM_INTEGRATION=1)",
      )
    True -> ledc_fades_live()
  }
}

fn ledc_fades_live() -> Result(Nil, Failure) {
  let mode = ledc.low_speed_mode()
  use _ <- result.try(expect.ok_or_runtime(
    "ledc.fade_func_install",
    ledc.fade_func_install(0),
    ledc_runtime,
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "ledc.set_fade_with_time",
    ledc.set_fade_with_time(mode, 0, 0, 100),
    ledc_runtime,
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "ledc.set_fade_with_step",
    ledc.set_fade_with_step(mode, 0, 0, 1, 1),
    ledc_runtime,
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "ledc.set_fade_time_and_start",
    ledc.set_fade_time_and_start(mode, 0, 0, 100, 0),
    ledc_runtime,
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "ledc.set_fade_step_and_start",
    ledc.set_fade_step_and_start(mode, 0, 0, 1, 1, 0),
    ledc_runtime,
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "ledc.fade_start",
    ledc.fade_start(mode, 0, 0),
    ledc_runtime,
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "ledc.fade_stop",
    ledc.fade_stop(mode, 0),
    ledc_runtime,
    ledc.error_to_string,
  ))
  expect.ok_or_runtime(
    "ledc.fade_func_uninstall",
    ledc.fade_func_uninstall(),
    ledc_runtime,
    ledc.error_to_string,
  )
}
