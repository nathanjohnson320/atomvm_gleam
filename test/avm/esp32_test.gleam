//// ESP32 suite — peripherals, buses, network entrypoints.

import atomvm_gleam/adc
import atomvm_gleam/esp
import atomvm_gleam/esp_dac
import atomvm_gleam/gpio
import atomvm_gleam/http
import atomvm_gleam/i2c
import atomvm_gleam/ledc
import atomvm_gleam/mdns
import atomvm_gleam/network
import atomvm_gleam/spi
import atomvm_gleam/ssl
import atomvm_gleam/uart
import atomvm_gleam/websocket
import avm/check.{type Failure}
import avm/expect
import gleam/bit_array
import gleam/option
import gleam/result

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

fn esp_ns(e: esp.Error) -> Bool {
  case e {
    esp.NotSupported -> True
    _ -> False
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
  use _ <- result.try(case esp.reset_reason() {
    esp.EspRstPoweron | esp.EspRstUnknown ->
      check.cover("esp.reset_reason", check.ok())
    _ -> check.fail("unexpected reset_reason (expected Poweron or Unknown)")
  })
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
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.get_mac",
    esp.get_mac(esp.WifiSta),
    esp_ns,
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
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.nvs_erase_all",
    esp.nvs_erase_all(namespace),
    esp_ns,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.nvs_erase_all_default",
    esp.nvs_erase_all_default(),
    esp_ns,
    esp.error_to_string,
  ))
  // nvs_reformat is destructive — skip in CI (not tagged).
  Ok(Nil)
}

fn rtc_slow_smoke() -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.rtc_slow_set_binary",
    esp.rtc_slow_set_binary(<<"rtc">>),
    esp_ns,
    esp.error_to_string,
  ))
  expect.ok_or_not_supported(
    "esp.rtc_slow_get_binary",
    esp.rtc_slow_get_binary(),
    esp_ns,
    esp.error_to_string,
  )
}

fn sleep_enable_reads() -> Result(Nil, Failure) {
  // Configure wakeup sources only (do not enter sleep).
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.sleep_enable_timer_wakeup",
    esp.sleep_enable_timer_wakeup(1_000_000),
    esp_ns,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.sleep_enable_gpio_wakeup",
    esp.sleep_enable_gpio_wakeup(),
    esp_ns,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.sleep_enable_ext0_wakeup",
    esp.sleep_enable_ext0_wakeup(0, 0),
    esp_ns,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.sleep_enable_ext1_wakeup",
    esp.sleep_enable_ext1_wakeup(1, 0),
    esp_ns,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.sleep_enable_ext1_wakeup_io",
    esp.sleep_enable_ext1_wakeup_io(1, 0),
    esp_ns,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.sleep_disable_ext1_wakeup_io",
    esp.sleep_disable_ext1_wakeup_io(1),
    esp_ns,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.deep_sleep_enable_gpio_wakeup",
    esp.deep_sleep_enable_gpio_wakeup(1, 0),
    esp_ns,
    esp.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "esp.sleep_enable_ulp_wakeup",
    esp.sleep_enable_ulp_wakeup(),
    esp_ns,
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
  use _ <- result.try(expect.ok_or_not_supported(
    "gpio.set_pin_pull",
    gpio.set_pin_pull(pin, gpio.Up),
    fn(e) {
      case e {
        gpio.NotSupported -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "gpio.init",
    gpio.init(pin),
    fn(e) {
      case e {
        gpio.NotSupported -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "gpio.digital_read",
    gpio.digital_read(pin),
    fn(e) {
      case e {
        gpio.NotSupported -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "gpio.hold_en",
    gpio.hold_en(pin),
    fn(e) {
      case e {
        gpio.NotSupported -> True
        _ -> False
      }
    },
    gpio.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "gpio.hold_dis",
    gpio.hold_dis(pin),
    fn(e) {
      case e {
        gpio.NotSupported -> True
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
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.channel_config",
    ledc.channel_config(ch),
    fn(e) {
      case e {
        ledc.NotSupported -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.set_duty",
    ledc.set_duty(mode, 0, 512),
    fn(e) {
      case e {
        ledc.NotSupported -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.update_duty",
    ledc.update_duty(mode, 0),
    fn(e) {
      case e {
        ledc.NotSupported -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.get_duty",
    ledc.get_duty(mode, 0),
    fn(e) {
      case e {
        ledc.NotSupported -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.get_freq",
    ledc.get_freq(mode, 0),
    fn(e) {
      case e {
        ledc.NotSupported -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.set_freq",
    ledc.set_freq(mode, 0, 4000),
    fn(e) {
      case e {
        ledc.NotSupported -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.set_duty_and_update",
    ledc.set_duty_and_update(mode, 0, 256, 0),
    fn(e) {
      case e {
        ledc.NotSupported -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.fade_func_install",
    ledc.fade_func_install(0),
    fn(e) {
      case e {
        ledc.NotSupported -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.fade_func_uninstall",
    ledc.fade_func_uninstall(),
    fn(e) {
      case e {
        ledc.NotSupported -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "ledc.stop",
    ledc.stop(mode, 0, 0),
    fn(e) {
      case e {
        ledc.NotSupported -> True
        _ -> False
      }
    },
    ledc.error_to_string,
  ))
  Ok(Nil)
}

fn adc_smoke() -> Result(Nil, Failure) {
  use unit_r <- result.try(expect.ok_value_or_not_supported(
    "adc.init",
    adc.init(),
    fn(e) {
      case e {
        adc.NotSupported -> True
        _ -> False
      }
    },
    adc.error_to_string,
  ))
  case unit_r {
    Error(Nil) -> {
      use _ <- result.try(check.cover_not_supported("adc.acquire"))
      use _ <- result.try(check.cover_not_supported("adc.acquire_default"))
      use _ <- result.try(check.cover_not_supported("adc.sample"))
      use _ <- result.try(check.cover_not_supported("adc.sample_with"))
      use _ <- result.try(check.cover_not_supported("adc.release_channel"))
      use _ <- result.try(check.cover_not_supported("adc.deinit"))
      Ok(Nil)
    }
    Ok(unit) -> {
      use ch_r <- result.try(expect.ok_value_or_not_supported(
        "adc.acquire_default",
        adc.acquire_default(36, unit),
        fn(e) {
          case e {
            adc.NotSupported -> True
            _ -> False
          }
        },
        adc.error_to_string,
      ))
      case ch_r {
        Error(Nil) -> {
          use _ <- result.try(check.cover_ok("adc.deinit", adc.deinit(unit)))
          Ok(Nil)
        }
        Ok(ch) -> {
          use _ <- result.try(expect.ok_or_not_supported(
            "adc.sample",
            adc.sample(ch, unit),
            fn(e) {
              case e {
                adc.NotSupported -> True
                _ -> False
              }
            },
            adc.error_to_string,
          ))
          use _ <- result.try(expect.ok_or_not_supported(
            "adc.sample_with",
            adc.sample_with(
              ch,
              unit,
              adc.SampleOptions(raw: True, voltage: True, samples: 8),
            ),
            fn(e) {
              case e {
                adc.NotSupported -> True
                _ -> False
              }
            },
            adc.error_to_string,
          ))
          use _ <- result.try(check.cover_ok(
            "adc.release_channel",
            adc.release_channel(ch),
          ))
          use _ <- result.try(check.cover_ok("adc.deinit", adc.deinit(unit)))
          use _ <- result.try(check.cover_not_supported("adc.acquire"))
          Ok(Nil)
        }
      }
    }
  }
}

fn dac_smoke() -> Result(Nil, Failure) {
  use ch_r <- result.try(expect.ok_value_or_not_supported(
    "esp_dac.new_channel",
    esp_dac.new_channel(esp_dac.Oneshot, esp_dac.OneshotOptions(chan_id: 0)),
    fn(e) {
      case e {
        esp_dac.NotSupported -> True
        _ -> False
      }
    },
    esp_dac.error_to_string,
  ))
  case ch_r {
    Error(Nil) -> {
      use _ <- result.try(check.cover_not_supported(
        "esp_dac.oneshot_output_voltage",
      ))
      use _ <- result.try(check.cover_not_supported(
        "esp_dac.oneshot_del_channel",
      ))
      Ok(Nil)
    }
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
  use bus_r <- result.try(expect.ok_value_or_not_supported(
    "i2c.open",
    i2c.open(i2c.Config(scl: 22, sda: 21, clock_speed_hz: 100_000)),
    fn(e) {
      case e {
        i2c.NotSupported -> True
        _ -> False
      }
    },
    i2c.error_to_string,
  ))
  case bus_r {
    Error(Nil) -> Nil
    Ok(bus) -> {
      let _ = check.cover_ok("i2c.close", i2c.close(bus))
      Nil
    }
  }
  use spi_r <- result.try(expect.ok_value_or_not_supported(
    "spi.open",
    spi.open(
      spi.Params(
        bus_config: spi.BusConfig(
          peripheral: option.Some("HSPI"),
          sclk: option.Some(14),
          mosi: option.Some(13),
          miso: option.Some(12),
          pico: option.None,
          poci: option.None,
        ),
        device_config: [],
      ),
    ),
    fn(e) {
      case e {
        spi.NotSupported -> True
        _ -> False
      }
    },
    spi.error_to_string,
  ))
  case spi_r {
    Error(Nil) -> Nil
    Ok(s) -> {
      let _ = check.cover_ok("spi.close", spi.close(s))
      Nil
    }
  }
  use uart_r <- result.try(expect.ok_value_or_not_supported(
    "uart.open",
    uart.open("UART1", uart.default_config()),
    fn(e) {
      case e {
        uart.NotSupported -> True
        _ -> False
      }
    },
    uart.error_to_string,
  ))
  case uart_r {
    Error(Nil) -> {
      use _ <- result.try(expect.ok_or_not_supported(
        "uart.open_default",
        uart.open_default(uart.default_config()),
        fn(e) {
          case e {
            uart.NotSupported -> True
            _ -> False
          }
        },
        uart.error_to_string,
      ))
      Ok(Nil)
    }
    Ok(u) -> {
      use _ <- result.try(check.cover_ok("uart.close", uart.close(u)))
      Ok(Nil)
    }
  }
}

fn network_stack_smoke() -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_not_supported(
    "network.sta_status",
    network.sta_status(),
    fn(e) {
      case e {
        network.NotSupported -> True
        _ -> False
      }
    },
    network.error_to_string,
  ))
  // ssl.start/stop return Nil; only call when the SSL app is present.
  case ssl.start() {
    Nil -> {
      let _ = ssl.stop()
      Nil
    }
  }
  use _ <- result.try(check.cover("ssl.start", check.ok()))
  use _ <- result.try(check.cover("ssl.stop", check.ok()))
  use _ <- result.try(expect.ok_or_not_supported(
    "http.connect",
    http.connect(http.Http, "127.0.0.1", 9, False, option.None),
    fn(e) {
      case e {
        http.NotSupported -> True
        _ -> False
      }
    },
    http.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "websocket.open",
    websocket.open(websocket.Config(
      url: "ws://127.0.0.1:1/",
      owner: option.None,
      verify: option.None,
      network_timeout_ms: option.None,
      disable_auto_reconnect: option.Some(True),
    )),
    fn(e) {
      case e {
        websocket.NotSupported -> True
        _ -> False
      }
    },
    websocket.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "mdns.serialize_dns_name",
    mdns.serialize_dns_name([<<"example">>, <<"local">>]),
    fn(e) {
      case e {
        mdns.NotSupported -> True
        _ -> False
      }
    },
    mdns.error_to_string,
  ))
  Ok(Nil)
}
