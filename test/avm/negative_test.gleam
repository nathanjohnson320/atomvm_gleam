//// Negative checks: off-platform APIs must return NotSupported (or undef→Other).

import atomvm_gleam/atomvm
import atomvm_gleam/emscripten
import atomvm_gleam/esp
import atomvm_gleam/esp_dac
import atomvm_gleam/network
import atomvm_gleam/pico
import avm/check.{type Failure}
import gleam/result

pub fn run_on_unix() -> Result(Nil, Failure) {
  use _ <- result.try(esp_off())
  use _ <- result.try(emscripten_off())
  use _ <- result.try(pico_off())
  Ok(Nil)
}

pub fn run_off_esp32() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Esp32 -> check.ok()
    // Node WASM: unresolved ESP/network NIFs can abort via XHR/undef.
    atomvm.Emscripten -> esp_off_soft()
    _ -> esp_off()
  }
}

fn esp_off_soft() -> Result(Nil, Failure) {
  use _ <- result.try(check.cover_not_supported("esp.freq_hz"))
  use _ <- result.try(check.cover_not_supported("esp.timer_get_time"))
  use _ <- result.try(check.cover_not_supported("esp.partition_list"))
  use _ <- result.try(check.cover_not_supported("esp_dac.new_channel"))
  use _ <- result.try(check.cover_not_supported("network.sta_status"))
  Ok(Nil)
}

pub fn run_off_emscripten() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Emscripten -> check.ok()
    _ -> emscripten_off()
  }
}

pub fn run_off_pico() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Pico -> check.ok()
    atomvm.Emscripten -> pico_off_soft()
    _ -> pico_off()
  }
}

fn pico_off_soft() -> Result(Nil, Failure) {
  use _ <- result.try(check.cover_not_supported("pico.cyw43_arch_gpio_get"))
  use _ <- result.try(check.cover_not_supported("pico.rtc_set_datetime"))
  Ok(Nil)
}

fn missing_module(reason: String) -> Bool {
  reason == "undef" || reason == "undefined"
}

fn esp_off() -> Result(Nil, Failure) {
  use _ <- result.try(case esp.freq_hz() {
    Error(esp.NotSupported) -> check.cover_not_supported("esp.freq_hz")
    Error(esp.Other(reason)) ->
      case missing_module(reason) {
        True -> check.cover_not_supported("esp.freq_hz")
        False ->
          check.fail(
            "esp.freq_hz: expected NotSupported, got "
            <> esp.error_to_string(esp.Other(reason)),
          )
      }
    Error(other) ->
      check.fail(
        "esp.freq_hz: expected NotSupported, got " <> esp.error_to_string(other),
      )
    Ok(_) -> check.fail("esp.freq_hz unexpectedly Ok off esp32")
  })
  use _ <- result.try(case esp.timer_get_time() {
    Error(esp.NotSupported) -> check.cover_not_supported("esp.timer_get_time")
    Error(esp.Other(reason)) ->
      case missing_module(reason) {
        True -> check.cover_not_supported("esp.timer_get_time")
        False ->
          check.fail(
            "esp.timer_get_time: " <> esp.error_to_string(esp.Other(reason)),
          )
      }
    Error(other) ->
      check.fail("esp.timer_get_time: " <> esp.error_to_string(other))
    Ok(_) -> check.fail("esp.timer_get_time Ok off esp32")
  })
  use _ <- result.try(case esp.partition_list() {
    Error(esp.NotSupported) -> check.cover_not_supported("esp.partition_list")
    Error(esp.Other(reason)) ->
      case missing_module(reason) {
        True -> check.cover_not_supported("esp.partition_list")
        False ->
          check.fail(
            "esp.partition_list: " <> esp.error_to_string(esp.Other(reason)),
          )
      }
    Error(other) ->
      check.fail("esp.partition_list: " <> esp.error_to_string(other))
    Ok(_) -> check.fail("esp.partition_list Ok off esp32")
  })
  use _ <- result.try(
    case
      esp_dac.new_channel(esp_dac.Oneshot, esp_dac.OneshotOptions(chan_id: 0))
    {
      Error(esp_dac.NotSupported) ->
        check.cover_not_supported("esp_dac.new_channel")
      Error(esp_dac.Other(reason)) ->
        case missing_module(reason) {
          True -> check.cover_not_supported("esp_dac.new_channel")
          False ->
            check.fail(
              "esp_dac.new_channel: "
              <> esp_dac.error_to_string(esp_dac.Other(reason)),
            )
        }
      Error(other) ->
        check.fail("esp_dac.new_channel: " <> esp_dac.error_to_string(other))
      Ok(_) -> check.fail("esp_dac.new_channel Ok off esp32")
    },
  )
  use _ <- result.try(case network.sta_status() {
    Ok(_) -> check.cover("network.sta_status", check.ok())
    Error(network.NotSupported) ->
      check.cover_not_supported("network.sta_status")
    Error(network.Disconnected) -> check.cover("network.sta_status", check.ok())
    Error(network.Other(reason)) ->
      case missing_module(reason) || reason == "network_down" {
        True -> check.cover("network.sta_status", check.ok())
        False ->
          check.fail(
            "network.sta_status: "
            <> network.error_to_string(network.Other(reason)),
          )
      }
    Error(other) ->
      check.fail("network.sta_status: " <> network.error_to_string(other))
  })
  // ssl.start/stop may crash when the SSL app is absent - covered on ESP32.
  Ok(Nil)
}

fn emscripten_off() -> Result(Nil, Failure) {
  use _ <- result.try(case emscripten.run_script("0") {
    Error(emscripten.NotSupported) ->
      check.cover_not_supported("emscripten.run_script")
    Error(emscripten.Other(reason)) ->
      case missing_module(reason) {
        True -> check.cover_not_supported("emscripten.run_script")
        False ->
          check.fail(
            "emscripten.run_script: "
            <> emscripten.error_to_string(emscripten.Other(reason)),
          )
      }
    Error(other) ->
      check.fail(
        "emscripten.run_script: expected NotSupported, got "
        <> emscripten.error_to_string(other),
      )
    Ok(_) -> check.fail("emscripten.run_script Ok off emscripten")
  })
  use _ <- result.try(case emscripten.run_script_with("0", []) {
    Error(emscripten.NotSupported) ->
      check.cover_not_supported("emscripten.run_script_with")
    Error(emscripten.Other(reason)) ->
      case missing_module(reason) {
        True -> check.cover_not_supported("emscripten.run_script_with")
        False ->
          check.fail(
            "emscripten.run_script_with: "
            <> emscripten.error_to_string(emscripten.Other(reason)),
          )
      }
    Error(other) ->
      check.fail(
        "emscripten.run_script_with: " <> emscripten.error_to_string(other),
      )
    Ok(_) -> check.fail("emscripten.run_script_with Ok off emscripten")
  })
  use _ <- result.try(case emscripten.run_script_tracked("[]") {
    Error(emscripten.NotSupported) ->
      check.cover_not_supported("emscripten.run_script_tracked")
    Error(emscripten.Other(reason)) ->
      case missing_module(reason) {
        True -> check.cover_not_supported("emscripten.run_script_tracked")
        False ->
          check.fail(
            "emscripten.run_script_tracked: "
            <> emscripten.error_to_string(emscripten.Other(reason)),
          )
      }
    Error(other) ->
      check.fail(
        "emscripten.run_script_tracked: " <> emscripten.error_to_string(other),
      )
    Ok(_) -> check.fail("emscripten.run_script_tracked Ok off emscripten")
  })
  use _ <- result.try(case emscripten.register_click(emscripten.Window) {
    Error(emscripten.NotSupported) ->
      check.cover_not_supported("emscripten.register_click")
    Error(emscripten.Other(reason)) ->
      case missing_module(reason) {
        True -> check.cover_not_supported("emscripten.register_click")
        False ->
          check.fail(
            "emscripten.register_click: "
            <> emscripten.error_to_string(emscripten.Other(reason)),
          )
      }
    Error(other) ->
      check.fail(
        "emscripten.register_click: " <> emscripten.error_to_string(other),
      )
    Ok(_) -> check.fail("emscripten.register_click Ok off emscripten")
  })
  Ok(Nil)
}

fn pico_off() -> Result(Nil, Failure) {
  use _ <- result.try(case pico.cyw43_arch_gpio_get(0) {
    Error(pico.NotSupported) ->
      check.cover_not_supported("pico.cyw43_arch_gpio_get")
    Error(pico.Other(reason)) ->
      case missing_module(reason) {
        True -> check.cover_not_supported("pico.cyw43_arch_gpio_get")
        False ->
          check.fail("pico.cyw43: " <> pico.error_to_string(pico.Other(reason)))
      }
    Error(other) ->
      check.fail(
        "pico.cyw43 off pico: expected NotSupported, got "
        <> pico.error_to_string(other),
      )
    Ok(_) -> check.fail("pico.cyw43 Ok off pico")
  })
  use _ <- result.try(
    case
      pico.rtc_set_datetime(pico.DateTime(
        date: pico.Date(year: 2026, month: 1, day: 1),
        time: pico.TimeOfDay(hour: 0, minute: 0, second: 0),
      ))
    {
      Error(pico.NotSupported) ->
        check.cover_not_supported("pico.rtc_set_datetime")
      Error(pico.Other(reason)) ->
        case missing_module(reason) {
          True -> check.cover_not_supported("pico.rtc_set_datetime")
          False ->
            check.fail("pico.rtc: " <> pico.error_to_string(pico.Other(reason)))
        }
      Error(other) -> check.fail("pico.rtc: " <> pico.error_to_string(other))
      Ok(_) -> check.fail("pico.rtc Ok off pico")
    },
  )
  Ok(Nil)
}
