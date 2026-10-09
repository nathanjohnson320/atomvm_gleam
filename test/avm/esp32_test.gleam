//// ESP32 suite — peripherals, buses, network entrypoints.

import atomvm_gleam/adc
import atomvm_gleam/esp
import atomvm_gleam/esp_dac
import atomvm_gleam/gpio
import atomvm_gleam/http
import atomvm_gleam/ledc
import atomvm_gleam/mdns
import atomvm_gleam/network
import atomvm_gleam/ssl
import atomvm_gleam/websocket
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/bit_array
import gleam/option
import gleam/result
import gleam/string

pub fn run() -> Result(Nil, Failure) {
  use _ <- result.try(freq_and_timer())
  use _ <- result.try(reset_and_wakeup())
  use _ <- result.try(mac_smoke())
  use _ <- result.try(partition_list_smoke())
  use _ <- result.try(nvs_roundtrip())
  use _ <- result.try(rtc_slow_smoke())
  use _ <- result.try(sleep_enable_reads())
  use _ <- result.try(gpio_nif())
  use _ <- result.try(ledc_smoke())
  use _ <- result.try(adc_smoke())
  use _ <- result.try(dac_smoke())
  use _ <- result.try(bus_smokes())
  use _ <- result.try(network_stack_smoke())
  Ok(Nil)
}

/// ESP32-owned APIs: Failed/Badarg ok on QEMU; NotSupported is a real failure.
fn esp_runtime(e: esp.Error) -> Bool {
  case e {
    esp.Failed | esp.Badarg | esp.Timeout | esp.NotFound | esp.Other(_) -> True
    esp.NotSupported -> False
  }
}

/// Wakeup-source config varies by chip / QEMU build — NotSupported allowed.
fn esp_wakeup_optional(e: esp.Error) -> Bool {
  case e {
    esp.NotSupported
    | esp.Failed
    | esp.Badarg
    | esp.Timeout
    | esp.NotFound
    | esp.Other(_) -> True
  }
}

fn freq_and_timer() -> Result(Nil, Failure) {
  use hz <- result.try(check.cover_ok("esp.freq_hz", esp.freq_hz()))
  use _ <- result.try(check.assert_true("freq_hz > 0", hz > 0))
  use us <- result.try(check.cover_ok(
    "esp.timer_get_time",
    esp.timer_get_time(),
  ))
  check.assert_true("timer_get_time >= 0", us >= 0)
}

fn reset_and_wakeup() -> Result(Nil, Failure) {
  // QEMU / warm restarts may report SW / other reasons — any known variant is fine.
  let _ = esp.reset_reason()
  use _ <- result.try(check.cover("esp.reset_reason", check.ok()))
  use _ <- result.try(check.cover_ok(
    "esp.sleep_get_wakeup_cause",
    esp.sleep_get_wakeup_cause(),
  ))
  Ok(Nil)
}

fn mac_smoke() -> Result(Nil, Failure) {
  use mac <- result.try(check.cover_ok(
    "esp.get_default_mac",
    esp.get_default_mac(),
  ))
  use _ <- result.try(check.assert_true(
    "mac len",
    bit_array.byte_size(mac) == 6,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "esp.get_mac",
    esp.get_mac(esp.WifiSta),
    esp_runtime,
    esp.error_to_string,
  ))
  Ok(Nil)
}

fn partition_list_smoke() -> Result(Nil, Failure) {
  use parts <- result.try(check.cover_ok(
    "esp.partition_list",
    esp.partition_list(),
  ))
  check.assert_true("partition_list non-empty", parts != [])
}

fn nvs_roundtrip() -> Result(Nil, Failure) {
  let namespace = "avmgltest"
  let key = "smoke"
  let payload = <<"gleam-nvs">>
  use _ <- result.try(check.cover_ok(
    "esp.nvs_put_binary",
    esp.nvs_put_binary(namespace, key, payload),
  ))
  use _ <- result.try(check.cover_ok(
    "esp.nvs_set_binary",
    esp.nvs_set_binary(namespace, key, payload),
  ))
  use got <- result.try(check.cover_ok(
    "esp.nvs_get_binary",
    esp.nvs_get_binary(namespace, key),
  ))
  use _ <- result.try(case got {
    option.Some(bytes) -> check.assert_eq("nvs payload", bytes, payload)
    option.None -> check.fail("nvs_get_binary returned None")
  })
  use _ <- result.try(check.cover_ok(
    "esp.nvs_fetch_binary",
    esp.nvs_fetch_binary(namespace, key),
  ))
  use _ <- result.try(check.cover_ok(
    "esp.nvs_get_binary_default",
    esp.nvs_get_binary_default(key),
  ))
  use _ <- result.try(check.cover_ok(
    "esp.nvs_set_binary_default",
    esp.nvs_set_binary_default(key, payload),
  ))
  use _ <- result.try(check.cover_ok(
    "esp.nvs_erase_key",
    esp.nvs_erase_key(namespace, key),
  ))
  use _ <- result.try(check.cover_ok(
    "esp.nvs_erase_key_default",
    esp.nvs_erase_key_default(key),
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "esp.nvs_erase_all",
    esp.nvs_erase_all(namespace),
    esp_runtime,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "esp.nvs_erase_all_default",
    esp.nvs_erase_all_default(),
    esp_runtime,
    esp.error_to_string,
  ))
  // nvs_reformat is destructive — skip in CI (not tagged).
  Ok(Nil)
}

fn rtc_slow_smoke() -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_runtime(
    "esp.rtc_slow_set_binary",
    esp.rtc_slow_set_binary(<<"rtc">>),
    esp_runtime,
    esp.error_to_string,
  ))
  expect.ok_or_runtime(
    "esp.rtc_slow_get_binary",
    esp.rtc_slow_get_binary(),
    esp_runtime,
    esp.error_to_string,
  )
}

fn sleep_enable_reads() -> Result(Nil, Failure) {
  // Configure wakeup sources only (do not enter sleep). Chip/QEMU may omit
  // some sources → NotSupported is acceptable here only.
  use _ <- result.try(expect.ok_or_runtime(
    "esp.sleep_enable_timer_wakeup",
    esp.sleep_enable_timer_wakeup(1_000_000),
    esp_wakeup_optional,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "esp.sleep_enable_gpio_wakeup",
    esp.sleep_enable_gpio_wakeup(),
    esp_wakeup_optional,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "esp.sleep_enable_ext0_wakeup",
    esp.sleep_enable_ext0_wakeup(0, 0),
    esp_wakeup_optional,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "esp.sleep_enable_ext1_wakeup",
    esp.sleep_enable_ext1_wakeup(1, 0),
    esp_wakeup_optional,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "esp.sleep_enable_ext1_wakeup_io",
    esp.sleep_enable_ext1_wakeup_io(1, 0),
    esp_wakeup_optional,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "esp.sleep_disable_ext1_wakeup_io",
    esp.sleep_disable_ext1_wakeup_io(1),
    esp_wakeup_optional,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "esp.deep_sleep_enable_gpio_wakeup",
    esp.deep_sleep_enable_gpio_wakeup(1, 0),
    esp_wakeup_optional,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "esp.sleep_enable_ulp_wakeup",
    esp.sleep_enable_ulp_wakeup(),
    esp_wakeup_optional,
    esp.error_to_string,
  ))
  Ok(Nil)
}

fn gpio_nif() -> Result(Nil, Failure) {
  let pin = gpio.pin(18)
  use _ <- result.try(check.cover_ok(
    "gpio.set_pin_mode",
    gpio.set_pin_mode(pin, gpio.Output),
  ))
  use _ <- result.try(check.cover_ok(
    "gpio.digital_write",
    gpio.digital_write(pin, gpio.PinHigh),
  ))
  use _ <- result.try(check.cover_ok(
    "gpio.digital_write",
    gpio.digital_write(pin, gpio.PinLow),
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.set_pin_pull",
    gpio.set_pin_pull(pin, gpio.Up),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.init",
    gpio.init(pin),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "gpio.digital_read",
    gpio.digital_read(pin),
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "gpio.hold_en",
    gpio.hold_en(pin),
    fn(e) {
      case e {
        gpio.Failed | gpio.Badarg -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "gpio.hold_dis",
    gpio.hold_dis(pin),
    fn(e) {
      case e {
        gpio.Failed | gpio.Badarg -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  Ok(Nil)
}

fn ledc_smoke() -> Result(Nil, Failure) {
  let mode = ledc.low_speed_mode()
  let config =
    ledc.TimerConfig(
      duty_resolution: 10,
      freq_hz: 5000,
      speed_mode: mode,
      timer_num: 0,
    )
  use _ <- result.try(check.cover_ok(
    "ledc.timer_config",
    ledc.timer_config(config),
  ))
  let ch =
    ledc.ChannelConfig(
      channel: 0,
      duty: 0,
      gpio_num: 4,
      speed_mode: mode,
      hpoint: 0,
      timer_sel: 0,
    )
  use _ <- result.try(expect.must_ok(
    "ledc.channel_config",
    ledc.channel_config(ch),
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "ledc.set_duty",
    ledc.set_duty(mode, 0, 512),
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "ledc.update_duty",
    ledc.update_duty(mode, 0),
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "ledc.get_duty",
    ledc.get_duty(mode, 0),
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "ledc.get_freq",
    ledc.get_freq(mode, 0),
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "ledc.set_freq",
    ledc.set_freq(mode, 0, 4000),
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "ledc.set_duty_and_update",
    ledc.set_duty_and_update(mode, 0, 256, 0),
    fn(e) {
      case e {
        ledc.Failed | ledc.Code(_) | ledc.Other(_) | ledc.Badarg -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "ledc.fade_func_install",
    ledc.fade_func_install(0),
    fn(e) {
      case e {
        ledc.Failed | ledc.Code(_) | ledc.Badarg -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_runtime(
    "ledc.fade_func_uninstall",
    ledc.fade_func_uninstall(),
    fn(e) {
      case e {
        ledc.Failed | ledc.Code(_) | ledc.Badarg -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.must_ok(
    "ledc.stop",
    ledc.stop(mode, 0, 0),
    ledc.error_to_string,
  ))
  Ok(Nil)
}

fn adc_smoke() -> Result(Nil, Failure) {
  use unit <- result.try(expect.must_ok_value(
    "adc.init",
    adc.init(),
    adc.error_to_string,
  ))
  use ch <- result.try(expect.must_ok_value(
    "adc.acquire_default",
    adc.acquire_default(36, unit),
    adc.error_to_string,
  ))
  // `adc.sample` can block indefinitely under Espressif QEMU after acquire.
  use _ <- result.try(case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    True -> {
      use _ <- result.try(expect.must_ok(
        "adc.sample",
        adc.sample(ch, unit),
        adc.error_to_string,
      ))
      expect.must_ok(
        "adc.sample_with",
        adc.sample_with(
          ch,
          unit,
          adc.SampleOptions(raw: True, voltage: True, samples: 8),
        ),
        adc.error_to_string,
      )
    }
    False ->
      integration.skip(
        "adc.sample / sample_with (QEMU hang; set AVM_GLEAM_INTEGRATION=1)",
      )
  })
  use _ <- result.try(check.cover_ok(
    "adc.release_channel",
    adc.release_channel(ch),
  ))
  check.cover_ok("adc.deinit", adc.deinit(unit))
}

fn dac_smoke() -> Result(Nil, Failure) {
  // DAC availability varies by chip / QEMU; Failed is ok, NotSupported is not.
  use ch_r <- result.try(expect.ok_value_or_runtime(
    "esp_dac.new_channel",
    esp_dac.new_channel(esp_dac.Oneshot, esp_dac.OneshotOptions(chan_id: 0)),
    fn(e) {
      case e {
        esp_dac.Failed | esp_dac.Badarg | esp_dac.Timeout | esp_dac.Other(_) ->
          True
        esp_dac.NotSupported -> False
      }
    },
    esp_dac.error_to_string,
  ))
  case ch_r {
    Error(Nil) -> Ok(Nil)
    Ok(ch) -> {
      use _ <- result.try(check.cover_ok(
        "esp_dac.oneshot_output_voltage",
        esp_dac.oneshot_output_voltage(ch, 128),
      ))
      check.cover_ok(
        "esp_dac.oneshot_del_channel",
        esp_dac.oneshot_del_channel(ch),
      )
    }
  }
}

fn bus_smokes() -> Result(Nil, Failure) {
  // i2c / spi / uart open+close live coverage lives in i2c_test, spi_test, and
  // uart_test (INTEGRATION-gated on ESP32 QEMU). Avoid duplicating hangs here.
  integration.skip(
    "i2c/spi/uart open covered by dedicated suites (INTEGRATION on ESP)",
  )
}

fn network_stack_smoke() -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_runtime(
    "network.sta_status",
    network.sta_status(),
    fn(e) {
      case e {
        network.Failed | network.Disconnected -> True
        network.Other(reason) ->
          string.contains(reason, "network_down")
          || string.contains(reason, "already_started")
        network.NotSupported -> False
        _ -> False
      }
    },
    network.error_to_string,
  ))
  case ssl.start() {
    Nil -> {
      let _ = ssl.stop()
      Nil
    }
  }
  use _ <- result.try(check.cover("ssl.start", check.ok()))
  use _ <- result.try(check.cover("ssl.stop", check.ok()))
  use _ <- result.try(expect.ok_or_runtime(
    "http.connect",
    http.connect(http.Http, "127.0.0.1", 9, False, option.None),
    fn(e) {
      case e {
        http.Failed | http.Timeout | http.Other(_) | http.Badarg -> True
        http.NotSupported -> False
      }
    },
    http.error_to_string,
  ))
  use _ <- result.try(case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    True ->
      expect.ok_or_runtime(
        "websocket.open",
        websocket.open(websocket.Config(
          url: "ws://127.0.0.1:1/",
          owner: option.None,
          verify: option.None,
          network_timeout_ms: option.Some(200),
          disable_auto_reconnect: option.Some(True),
        )),
        fn(e) {
          case e {
            websocket.Failed
            | websocket.Timeout
            | websocket.Badarg
            | websocket.Other(_)
            | websocket.MissingUrl
            | websocket.NotConnected -> True
            websocket.NotSupported -> False
          }
        },
        websocket.error_to_string,
      )
    False ->
      integration.skip(
        "websocket.open (QEMU hang; set AVM_GLEAM_INTEGRATION=1)",
      )
  })
  expect.must_ok(
    "mdns.serialize_dns_name",
    mdns.serialize_dns_name([<<"example">>, <<"local">>]),
    mdns.error_to_string,
  )
}
