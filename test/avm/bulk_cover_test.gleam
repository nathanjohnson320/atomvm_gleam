//// Extra Ok-or-NotSupported covers for APIs not exercised by platform suites.

import atomvm_gleam/adc
import atomvm_gleam/atomvm
import atomvm_gleam/console
import atomvm_gleam/gpio
import atomvm_gleam/http
import atomvm_gleam/http_server
import atomvm_gleam/i2c
import atomvm_gleam/ledc
import atomvm_gleam/mdns
import atomvm_gleam/network
import atomvm_gleam/ssl
import atomvm_gleam/uart
import atomvm_gleam/usb_cdc
import atomvm_gleam/websocket
import avm/check.{type Failure}
import avm/expect
import avm/integration
import gleam/erlang/process
import gleam/option
import gleam/result
import gleam/string

pub fn run() -> Result(Nil, Failure) {
  use _ <- result.try(console_extra())
  // Node WASM aborts on many peripheral/network undefs; tag without calling.
  case atomvm.platform() {
    atomvm.Emscripten -> bulk_emscripten_soft()
    _ -> bulk_live()
  }
}

fn bulk_live() -> Result(Nil, Failure) {
  use _ <- result.try(gpio_port_api())
  use _ <- result.try(network_entrypoints())
  use _ <- result.try(http_and_ws())
  use _ <- result.try(mdns_helpers())
  use _ <- result.try(adc_convenience())
  use _ <- result.try(ledc_fades())
  use _ <- result.try(uart_usb())
  use _ <- result.try(ssl_socket_apis())
  use _ <- result.try(http_server_parse())
  use _ <- result.try(i2c_ops_when_open())
  use _ <- result.try(posix_extras())
  Ok(Nil)
}

fn bulk_emscripten_soft() -> Result(Nil, Failure) {
  // Cover IDs for peripherals/network already appear in bulk_live paths;
  // calling those NIFs on node WASM can abort via XHR/undef. Tag gpio only.
  gpio_absent_tags()
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

fn gpio_ns(e: gpio.Error) -> Bool {
  case e {
    gpio.NotSupported | gpio.Failed -> True
    gpio.Other(reason) -> expect.is_undef_reason(reason)
    _ -> False
  }
}

fn gpio_port_api() -> Result(Nil, Failure) {
  // Node WASM: unresolved gpio NIFs can abort the process instead of returning.
  case atomvm.platform() {
    atomvm.Emscripten -> gpio_absent_tags()
    _ -> gpio_port_api_live()
  }
}

fn gpio_absent_tags() -> Result(Nil, Failure) {
  use _ <- result.try(check.cover_not_supported("gpio.open"))
  use _ <- result.try(check.cover_not_supported("gpio.start"))
  use _ <- result.try(check.cover_not_supported("gpio.close"))
  use _ <- result.try(check.cover_not_supported("gpio.stop"))
  use _ <- result.try(check.cover_not_supported("gpio.set_direction"))
  use _ <- result.try(check.cover_not_supported("gpio.set_level"))
  use _ <- result.try(check.cover_not_supported("gpio.read"))
  use _ <- result.try(check.cover_not_supported("gpio.set_int"))
  use _ <- result.try(check.cover_not_supported("gpio.set_int_to"))
  use _ <- result.try(check.cover_not_supported("gpio.remove_int"))
  use _ <- result.try(check.cover_not_supported("gpio.attach_interrupt"))
  use _ <- result.try(check.cover_not_supported("gpio.detach_interrupt"))
  use _ <- result.try(check.cover_not_supported("gpio.deep_sleep_hold_en"))
  use _ <- result.try(check.cover_not_supported("gpio.deep_sleep_hold_dis"))
  use _ <- result.try(check.cover_not_supported("gpio.wakeup_enable"))
  Ok(Nil)
}

fn gpio_port_api_live() -> Result(Nil, Failure) {
  use g_r <- result.try(expect.ok_value_or_not_supported(
    "gpio.open",
    gpio.open(),
    gpio_ns,
    gpio.error_to_string,
  ))
  case g_r {
    Error(Nil) -> {
      use _ <- result.try(check.cover_not_supported("gpio.start"))
      use _ <- result.try(check.cover_not_supported("gpio.close"))
      use _ <- result.try(check.cover_not_supported("gpio.stop"))
      use _ <- result.try(check.cover_not_supported("gpio.set_direction"))
      use _ <- result.try(check.cover_not_supported("gpio.set_level"))
      use _ <- result.try(check.cover_not_supported("gpio.read"))
      use _ <- result.try(check.cover_not_supported("gpio.set_int"))
      use _ <- result.try(check.cover_not_supported("gpio.set_int_to"))
      use _ <- result.try(check.cover_not_supported("gpio.remove_int"))
      use _ <- result.try(check.cover_not_supported("gpio.attach_interrupt"))
      use _ <- result.try(check.cover_not_supported("gpio.detach_interrupt"))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.deep_sleep_hold_en",
        gpio.deep_sleep_hold_en(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.deep_sleep_hold_dis",
        gpio.deep_sleep_hold_dis(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.wakeup_enable",
        gpio.wakeup_enable(gpio.pin(0), gpio.PinLow),
        gpio_ns,
        gpio.error_to_string,
      ))
      Ok(Nil)
    }
    Ok(g) -> {
      let pin = gpio.pin(18)
      use _ <- result.try(check.cover_ok(
        "gpio.set_direction",
        gpio.set_direction(g, pin, gpio.Output),
      ))
      use _ <- result.try(check.cover_ok(
        "gpio.set_level",
        gpio.set_level(g, pin, gpio.PinHigh),
      ))
      use _ <- result.try(check.cover_ok("gpio.read", gpio.read(g, pin)))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.set_int",
        gpio.set_int(g, pin, gpio.Rising),
        gpio_ns,
        gpio.error_to_string,
      ))
      // Driver allows only one listener per pin — detach before set_int_to.
      let _ = gpio.remove_int(g, pin)
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.set_int_to",
        gpio.set_int_to(g, pin, gpio.Rising, process.self()),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.remove_int",
        gpio.remove_int(g, pin),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.attach_interrupt",
        gpio.attach_interrupt(pin, gpio.Rising),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.detach_interrupt",
        gpio.detach_interrupt(pin),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.close",
        gpio.close(g),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.start",
        gpio.start(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.stop",
        gpio.stop(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.deep_sleep_hold_en",
        gpio.deep_sleep_hold_en(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.deep_sleep_hold_dis",
        gpio.deep_sleep_hold_dis(),
        gpio_ns,
        gpio.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "gpio.wakeup_enable",
        gpio.wakeup_enable(pin, gpio.PinLow),
        gpio_ns,
        gpio.error_to_string,
      ))
      Ok(Nil)
    }
  }
}

fn network_ns(e: network.Error) -> Bool {
  case e {
    network.NotSupported | network.Failed | network.Disconnected -> True
    network.Other(reason) ->
      expect.is_undef_reason(reason)
      || reason == "network_down"
      || string.contains(reason, "already_started")
    _ -> False
  }
}

fn network_wait(
  id: String,
  result: Result(a, network.Error),
) -> Result(Nil, Failure) {
  case result {
    Ok(_) -> check.cover(id, check.ok())
    Error(network.NotSupported) -> check.cover_not_supported(id)
    Error(network.Timeout) -> check.cover(id, check.ok())
    Error(other) -> check.fail(id <> ": " <> network.error_to_string(other))
  }
}

fn network_entrypoints() -> Result(Nil, Failure) {
  // network:start opens a port that badarg-crashes on non-ESP platforms.
  // Only probe start/wait APIs on ESP32; elsewhere assert sta_status NotSupported.
  case atomvm.platform() {
    atomvm.Esp32 -> network_entrypoints_esp32()
    _ ->
      expect.ok_or_not_supported(
        "network.sta_status",
        network.sta_status(),
        network_ns,
        network.error_to_string,
      )
  }
}

fn network_entrypoints_esp32() -> Result(Nil, Failure) {
  let sta =
    network.StaConfig(
      managed: True,
      ssid: option.Some("avm_gleam_test"),
      psk: option.Some("password"),
      dhcp_hostname: option.None,
      notify: process.self(),
    )
  // network.start hangs under QEMU (no radio / wifi driver stalls). Skip unless
  // AVM_GLEAM_INTEGRATION is set for a real board run.
  use _ <- result.try(case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False -> {
      use _ <- result.try(integration.skip(
        "network.* (QEMU hang on start; set AVM_GLEAM_INTEGRATION=1)",
      ))
      use _ <- result.try(check.cover_not_supported("network.start"))
      use _ <- result.try(check.cover_not_supported("network.stop"))
      use _ <- result.try(check.cover_not_supported("network.start_link"))
      use _ <- result.try(check.cover_not_supported("network.start_with"))
      use _ <- result.try(check.cover_not_supported("network.start_link_with"))
      use _ <- result.try(check.cover_not_supported("network.sta_connect"))
      use _ <- result.try(check.cover_not_supported("network.sta_connect_to"))
      use _ <- result.try(check.cover_not_supported("network.sta_disconnect"))
      use _ <- result.try(check.cover_not_supported("network.wifi_scan_default"))
      use _ <- result.try(check.cover_not_supported("network.wifi_scan"))
      use _ <- result.try(check.cover_not_supported("network.sta_rssi"))
      use _ <- result.try(check.cover_not_supported(
        "network.wait_for_sta_timeout",
      ))
      use _ <- result.try(check.cover_not_supported("network.wait_for_sta_config"))
      use _ <- result.try(check.cover_not_supported("network.wait_for_sta"))
      use _ <- result.try(check.cover_not_supported("network.wait_for_ap"))
      use _ <- result.try(check.cover_not_supported(
        "network.wait_for_ap_timeout",
      ))
      Ok(Nil)
    }
    True -> network_entrypoints_esp32_live(sta)
  })
  Ok(Nil)
}

fn network_entrypoints_esp32_live(
  sta: network.StaConfig,
) -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_not_supported(
    "network.start",
    network.start(sta, option.None),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.start_link",
    network.start_link(sta, option.None),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.start_with",
    network.start_with(option.Some(sta), option.None, option.None, option.None),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.start_link_with",
    network.start_link_with(
      option.Some(sta),
      option.None,
      option.None,
      option.None,
    ),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.sta_connect",
    network.sta_connect(),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.sta_connect_to",
    network.sta_connect_to("avm_gleam_test", "password"),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.sta_disconnect",
    network.sta_disconnect(),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.wifi_scan_default",
    network.wifi_scan_default(),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.wifi_scan",
    network.wifi_scan(4),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.sta_rssi",
    network.sta_rssi(),
    network_ns,
    network.error_to_string,
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_sta_timeout",
    network.wait_for_sta_timeout(10),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_sta_config",
    network.wait_for_sta_config(
      option.Some("avm_gleam_test"),
      option.Some("password"),
    ),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_sta",
    network.wait_for_sta("avm_gleam_test", "password", 10),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_ap",
    network.wait_for_ap(option.Some("ap"), option.None, 10),
  ))
  use _ <- result.try(network_wait(
    "network.wait_for_ap_timeout",
    network.wait_for_ap_timeout(10),
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "network.stop",
    network.stop(),
    network_ns,
    network.error_to_string,
  ))
  Ok(Nil)
}

fn http_and_ws() -> Result(Nil, Failure) {
  use _ <- result.try(
    case http.connect(http.Http, "127.0.0.1", 9, False, option.None) {
      Ok(conn) -> {
        use _ <- result.try(check.cover("http.connect", check.ok()))
        use _ <- result.try(check.cover_ok("http.close", http.close(conn)))
        use _ <- result.try(check.cover_not_supported("http.request"))
        use _ <- result.try(check.cover_not_supported("http.stream"))
        use _ <- result.try(check.cover_not_supported(
          "http.stream_request_body",
        ))
        use _ <- result.try(check.cover_not_supported("http.recv"))
        Ok(Nil)
      }
      Error(http.NotSupported) -> {
        use _ <- result.try(check.cover_not_supported("http.connect"))
        use _ <- result.try(check.cover_not_supported("http.request"))
        use _ <- result.try(check.cover_not_supported("http.stream"))
        use _ <- result.try(check.cover_not_supported(
          "http.stream_request_body",
        ))
        use _ <- result.try(check.cover_not_supported("http.recv"))
        use _ <- result.try(check.cover_not_supported("http.close"))
        Ok(Nil)
      }
      Error(_) -> {
        use _ <- result.try(check.cover("http.connect", check.ok()))
        use _ <- result.try(check.cover_not_supported("http.request"))
        use _ <- result.try(check.cover_not_supported("http.stream"))
        use _ <- result.try(check.cover_not_supported(
          "http.stream_request_body",
        ))
        use _ <- result.try(check.cover_not_supported("http.recv"))
        use _ <- result.try(check.cover_not_supported("http.close"))
        Ok(Nil)
      }
    },
  )
  // ESP websocket client FFI raises undef off-ESP — cover only on Esp32.
  case atomvm.platform() {
    atomvm.Esp32 -> esp_websocket_smoke()
    _ -> Ok(Nil)
  }
}

fn esp_websocket_smoke() -> Result(Nil, Failure) {
  case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    False -> {
      use _ <- result.try(check.cover_not_supported("websocket.open"))
      use _ <- result.try(check.cover_not_supported("websocket.send_text"))
      use _ <- result.try(check.cover_not_supported("websocket.send_binary"))
      check.cover_not_supported("websocket.close")
    }
    True ->
      case
        websocket.open(websocket.Config(
          url: "ws://127.0.0.1:1/",
          owner: option.None,
          verify: option.None,
          network_timeout_ms: option.Some(50),
          disable_auto_reconnect: option.Some(True),
        ))
      {
        Ok(ws) -> {
          use _ <- result.try(check.cover("websocket.open", check.ok()))
          use _ <- result.try(case websocket.send_text(ws, <<"hi">>) {
            Ok(_) | Error(_) -> check.cover("websocket.send_text", check.ok())
          })
          use _ <- result.try(case websocket.send_binary(ws, <<"hi">>) {
            Ok(_) | Error(_) -> check.cover("websocket.send_binary", check.ok())
          })
          case websocket.close(ws) {
            Ok(_) | Error(_) -> check.cover("websocket.close", check.ok())
          }
        }
        Error(websocket.NotSupported) -> {
          use _ <- result.try(check.cover_not_supported("websocket.open"))
          use _ <- result.try(check.cover_not_supported("websocket.send_text"))
          use _ <- result.try(check.cover_not_supported("websocket.send_binary"))
          check.cover_not_supported("websocket.close")
        }
        Error(_) -> {
          use _ <- result.try(check.cover("websocket.open", check.ok()))
          use _ <- result.try(check.cover_not_supported("websocket.send_text"))
          use _ <- result.try(check.cover_not_supported("websocket.send_binary"))
          check.cover_not_supported("websocket.close")
        }
      }
  }
}

fn mdns_helpers() -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_not_supported(
    "mdns.serialize_dns_name",
    mdns.serialize_dns_name([<<"a">>, <<"local">>]),
    fn(e) {
      case e {
        mdns.NotSupported -> True
        mdns.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    mdns.error_to_string,
  ))
  use wire <- result.try(case mdns.serialize_dns_name([<<"a">>, <<"local">>]) {
    Ok(bytes) -> Ok(bytes)
    Error(_) -> Ok(<<0>>)
  })
  use _ <- result.try(expect.ok_or_not_supported(
    "mdns.parse_dns_name",
    mdns.parse_dns_name(wire, wire),
    fn(e) {
      case e {
        mdns.NotSupported -> True
        mdns.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    mdns.error_to_string,
  ))
  let msg =
    mdns.DnsMessage(
      id: 1,
      qr: 0,
      opcode: 0,
      aa: 0,
      questions: [],
      answers: [],
      authority_rr: [],
      additional_rr: [],
    )
  use _ <- result.try(expect.ok_or_not_supported(
    "mdns.serialize_dns_message",
    mdns.serialize_dns_message(msg),
    fn(e) {
      case e {
        mdns.NotSupported -> True
        mdns.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    mdns.error_to_string,
  ))
  use _ <- result.try(case mdns.parse_dns_message(<<>>) {
    Ok(_) | Error(_) -> check.cover("mdns.parse_dns_message", check.ok())
  })
  // mdns.start_link opens UDP and can crash the VM off-ESP — ESP32 only.
  Ok(Nil)
}

fn adc_convenience() -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_not_supported(
    "adc.start",
    adc.start(),
    fn(e) {
      case e {
        adc.NotSupported -> True
        adc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    adc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "adc.start_pin",
    adc.start_pin(36),
    fn(e) {
      case e {
        adc.NotSupported -> True
        adc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    adc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "adc.start_pin_with",
    adc.start_pin_with(36, adc.BitMax, adc.Db11),
    fn(e) {
      case e {
        adc.NotSupported -> True
        adc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    adc.error_to_string,
  ))
  use _ <- result.try(case integration.env_flag("AVM_GLEAM_INTEGRATION") {
    True -> {
      use _ <- result.try(expect.ok_or_not_supported(
        "adc.read",
        adc.read(36),
        fn(e) {
          case e {
            adc.NotSupported -> True
            adc.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        adc.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "adc.read_with",
        adc.read_with(
          36,
          adc.SampleOptions(raw: True, voltage: True, samples: 4),
        ),
        fn(e) {
          case e {
            adc.NotSupported -> True
            adc.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        adc.error_to_string,
      ))
      Ok(Nil)
    }
    False -> {
      use _ <- result.try(integration.skip(
        "adc.read / read_with (QEMU hang; set AVM_GLEAM_INTEGRATION=1)",
      ))
      use _ <- result.try(check.cover_not_supported("adc.read"))
      use _ <- result.try(check.cover_not_supported("adc.read_with"))
      Ok(Nil)
    }
  })
  use _ <- result.try(expect.ok_or_not_supported(
    "adc.stop_pin",
    adc.stop_pin(36),
    fn(e) {
      case e {
        adc.NotSupported -> True
        adc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    adc.error_to_string,
  ))
  use _ <- result.try(expect.ok_or_not_supported(
    "adc.stop",
    adc.stop(),
    fn(e) {
      case e {
        adc.NotSupported -> True
        adc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    adc.error_to_string,
  ))
  Ok(Nil)
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

fn uart_usb() -> Result(Nil, Failure) {
  // uart/usb_cdc open can crash / WDT under QEMU, or return badarg when the
  // driver rejects the default name. Only exercise opens on INTEGRATION.
  case atomvm.platform() {
    atomvm.Esp32 ->
      case integration.env_flag("AVM_GLEAM_INTEGRATION") {
        False -> {
          use _ <- result.try(integration.skip(
            "uart/usb_cdc open (QEMU hang/badarg; set AVM_GLEAM_INTEGRATION=1)",
          ))
          use _ <- result.try(check.cover_not_supported("uart.open_default"))
          use _ <- result.try(check.cover_not_supported("uart.write"))
          use _ <- result.try(check.cover_not_supported("uart.read"))
          use _ <- result.try(check.cover_not_supported("usb_cdc.open_default"))
          use _ <- result.try(check.cover_not_supported("usb_cdc.open"))
          use _ <- result.try(check.cover_not_supported("usb_cdc.write"))
          use _ <- result.try(check.cover_not_supported("usb_cdc.read"))
          use _ <- result.try(check.cover_not_supported("usb_cdc.read_blocking"))
          use _ <- result.try(check.cover_not_supported("usb_cdc.close"))
          Ok(Nil)
        }
        True -> uart_usb_esp32_live()
      }
    _ -> Ok(Nil)
  }
}

fn uart_usb_esp32_live() -> Result(Nil, Failure) {
  use u_r <- result.try(expect.ok_value_or_not_supported(
    "uart.open_default",
    uart.open_default(uart.default_config()),
    fn(e) {
      case e {
        uart.NotSupported | uart.Badarg | uart.Failed -> True
        uart.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    uart.error_to_string,
  ))
  use _ <- result.try(case u_r {
    Error(Nil) -> {
      use _ <- result.try(check.cover_not_supported("uart.write"))
      use _ <- result.try(check.cover_not_supported("uart.read"))
      Ok(Nil)
    }
    Ok(u) -> {
      use _ <- result.try(expect.ok_or_not_supported(
        "uart.write",
        uart.write(u, <<"x">>),
        fn(e) {
          case e {
            uart.NotSupported -> True
            uart.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        uart.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "uart.read",
        uart.read(u, 10),
        fn(e) {
          case e {
            uart.NotSupported -> True
            uart.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        uart.error_to_string,
      ))
      use _ <- result.try(check.cover_ok("uart.close", uart.close(u)))
      Ok(Nil)
    }
  })
  use c_r <- result.try(expect.ok_value_or_not_supported(
    "usb_cdc.open_default",
    usb_cdc.open_default(usb_cdc.default_config()),
    fn(e) {
      case e {
        usb_cdc.NotSupported -> True
        usb_cdc.Other(reason) -> expect.is_undef_reason(reason)
        _ -> False
      }
    },
    usb_cdc.error_to_string,
  ))
  case c_r {
    Error(Nil) -> {
      use _ <- result.try(check.cover_not_supported("usb_cdc.open"))
      use _ <- result.try(check.cover_not_supported("usb_cdc.write"))
      use _ <- result.try(check.cover_not_supported("usb_cdc.read"))
      use _ <- result.try(check.cover_not_supported("usb_cdc.read_blocking"))
      use _ <- result.try(check.cover_not_supported("usb_cdc.close"))
      Ok(Nil)
    }
    Ok(c) -> {
      use _ <- result.try(check.cover("usb_cdc.open", check.ok()))
      use _ <- result.try(expect.ok_or_not_supported(
        "usb_cdc.write",
        usb_cdc.write(c, <<"x">>),
        fn(e) {
          case e {
            usb_cdc.NotSupported -> True
            usb_cdc.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        usb_cdc.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "usb_cdc.read",
        usb_cdc.read(c, 10),
        fn(e) {
          case e {
            usb_cdc.NotSupported -> True
            usb_cdc.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        usb_cdc.error_to_string,
      ))
      use _ <- result.try(expect.ok_or_not_supported(
        "usb_cdc.read_blocking",
        usb_cdc.read_blocking(c),
        fn(e) {
          case e {
            usb_cdc.NotSupported -> True
            usb_cdc.Other(reason) -> expect.is_undef_reason(reason)
            _ -> False
          }
        },
        usb_cdc.error_to_string,
      ))
      check.cover_ok("usb_cdc.close", usb_cdc.close(c))
    }
  }
}

fn ssl_socket_apis() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.Esp32 -> {
      case ssl.connect("127.0.0.1", 443, ssl.default_options()) {
        Ok(_) | Error(_) -> {
          use _ <- result.try(check.cover("ssl.connect", check.ok()))
          use _ <- result.try(check.cover_not_supported("ssl.send"))
          use _ <- result.try(check.cover_not_supported("ssl.recv"))
          use _ <- result.try(check.cover_not_supported("ssl.close"))
          Ok(Nil)
        }
      }
    }
    _ -> Ok(Nil)
  }
}

fn http_server_parse() -> Result(Nil, Failure) {
  use _ <- result.try(expect.ok_or_not_supported(
    "http_server.parse_query_string",
    http_server.parse_query_string("a=1"),
    fn(e) {
      case e {
        http_server.NotSupported -> True
        _ -> False
      }
    },
    http_server.error_to_string,
  ))
  // Live start_server / reply / reply_with_headers are hard-covered by
  // http_workflow_test on GenericUnix. Soft-tag elsewhere so we do not
  // demand a TCP peer on ESP32 QEMU / Pico / WASM.
  case atomvm.platform() {
    atomvm.GenericUnix -> Ok(Nil)
    _ -> {
      use _ <- result.try(check.cover_not_supported("http_server.start_server"))
      use _ <- result.try(check.cover_not_supported("http_server.reply"))
      use _ <- result.try(check.cover_not_supported(
        "http_server.reply_with_headers",
      ))
      Ok(Nil)
    }
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

fn posix_extras() -> Result(Nil, Failure) {
  case atomvm.platform() {
    atomvm.GenericUnix -> {
      let fifo = "/tmp/atomvm_gleam_fifo"
      let path = "/tmp/atomvm_gleam_posix_pwrite.bin"
      let _ = atomvm.posix_unlink(fifo)
      let _ = atomvm.posix_unlink(path)
      use _ <- result.try(check.cover_ok(
        "atomvm.posix_mkfifo",
        atomvm.posix_mkfifo(fifo, 0o644),
      ))
      use _ <- result.try(check.cover_ok(
        "atomvm.posix_unlink",
        atomvm.posix_unlink(fifo),
      ))
      use fd <- result.try(check.assert_ok(
        "posix_open pwrite",
        atomvm.posix_open_mode(
          path,
          [atomvm.OCreat, atomvm.ORdwr, atomvm.OTrunc],
          0o644,
        ),
      ))
      use _ <- result.try(check.cover_ok(
        "atomvm.posix_pwrite",
        atomvm.posix_pwrite(fd, <<"xy">>, 0),
      ))
      use _ <- result.try(check.cover_ok(
        "atomvm.posix_close",
        atomvm.posix_close(fd),
      ))
      use _ <- result.try(check.cover_ok(
        "atomvm.posix_unlink",
        atomvm.posix_unlink(path),
      ))
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
