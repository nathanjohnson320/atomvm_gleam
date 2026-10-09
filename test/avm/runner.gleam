//// AtomVM entrypoint. Pack this module first (`start/0`).

import atomvm_gleam/atomvm
import avm/adc_test
import avm/check.{type Failure, Failure}
import avm/crypto_test
import avm/emscripten_events_test
import avm/emscripten_test
import avm/emscripten_websocket_test
import avm/esp32_test
import avm/gpio_int_test
import avm/gpio_test
import avm/gpio_unix_test
import avm/http_server_test
import avm/http_test
import avm/http_workflow_test
import avm/i2c_test
import avm/json_test
import avm/ledc_test
import avm/log
import avm/mdns_test
import avm/negative_test
import avm/network_test
import avm/pico_test
import avm/portable_test
import avm/posix_test
import avm/pubsub_test
import avm/spi_test
import avm/ssl_test
import avm/stm32_test
import avm/uart_loopback_test
import avm/uart_test
import avm/usb_cdc_test
import avm/websocket_test
import gleam/erlang/atom.{type Atom}
import gleam/list

pub fn start() -> Atom {
  case run_all() {
    Ok(Nil) -> {
      log.line("AVM_GLEAM_TESTS_OK")
      atom.create("ok")
    }
    Error(failures) -> {
      log.line("AVM_GLEAM_TESTS_FAIL")
      log.line(check.join_failures(failures))
      atom.create("error")
    }
  }
}

pub fn main() -> Nil {
  let _ = start()
  Nil
}

fn common_module_suites() -> List(#(String, fn() -> Result(Nil, Failure))) {
  [
    #("gpio", gpio_test.run),
    #("network", network_test.run),
    #("http", http_test.run),
    #("websocket", websocket_test.run),
    #("mdns", mdns_test.run),
    #("adc", adc_test.run),
    #("ledc", ledc_test.run),
    #("uart", uart_test.run),
    #("usb_cdc", usb_cdc_test.run),
    #("ssl", ssl_test.run),
    #("http_server", http_server_test.run),
    #("i2c", i2c_test.run),
    #("spi", spi_test.run),
  ]
}

fn run_all() -> Result(Nil, List(Failure)) {
  let suites = case atomvm.platform() {
    atomvm.GenericUnix ->
      list.append(
        [
          #("portable", portable_test.run),
          #("crypto", crypto_test.run),
          #("json", json_test.run),
          #("posix", posix_test.run),
          #("gpio_unix", gpio_unix_test.run),
          #("pubsub", pubsub_test.run),
          #("http_workflow", http_workflow_test.run),
          #("uart_loopback", uart_loopback_test.run),
        ],
        list.append(common_module_suites(), [
          #("negative_esp", negative_test.run_on_unix),
          #("negative_emscripten", negative_test.run_off_emscripten),
          #("negative_pico", negative_test.run_off_pico),
        ]),
      )
    atomvm.Esp32 ->
      list.append(
        [
          #("portable", portable_test.run),
          #("crypto", crypto_test.run),
          #("json", json_test.run),
          #("esp32", esp32_test.run),
          #("gpio_int", gpio_int_test.run),
        ],
        list.append(common_module_suites(), [
          #("negative_emscripten", negative_test.run_off_emscripten),
          #("negative_pico", negative_test.run_off_pico),
        ]),
      )
    atomvm.Pico ->
      list.append(
        [
          #("portable", portable_test.run),
          #("crypto", crypto_test.run),
          #("json", json_test.run),
          #("pico", pico_test.run),
        ],
        list.append(common_module_suites(), [
          #("negative_esp", negative_test.run_off_esp32),
          #("negative_emscripten", negative_test.run_off_emscripten),
        ]),
      )
    atomvm.Stm32 ->
      list.append(
        [
          #("portable", portable_test.run),
          #("crypto", crypto_test.run),
          #("json", json_test.run),
          #("stm32", stm32_test.run),
        ],
        list.append(common_module_suites(), [
          #("negative_esp", negative_test.run_off_esp32),
          #("negative_emscripten", negative_test.run_off_emscripten),
          #("negative_pico", negative_test.run_off_pico),
        ]),
      )
    atomvm.Emscripten ->
      list.append(
        [
          #("portable", portable_test.run),
          #("crypto", crypto_test.run),
          #("json", json_test.run),
          #("emscripten", emscripten_test.run),
          #("emscripten_events", emscripten_events_test.run),
          #("emscripten_websocket", emscripten_websocket_test.run),
        ],
        list.append(common_module_suites(), [
          #("negative_esp", negative_test.run_off_esp32),
          #("negative_pico", negative_test.run_off_pico),
        ]),
      )
  }
  run_suites(suites, [])
}

fn run_suites(
  suites: List(#(String, fn() -> Result(Nil, Failure))),
  failures: List(Failure),
) -> Result(Nil, List(Failure)) {
  case suites {
    [] ->
      case failures {
        [] -> Ok(Nil)
        _ -> Error(list.reverse(failures))
      }
    [#(name, run), ..rest] -> {
      log.line("SUITE " <> name)
      case run() {
        Ok(Nil) -> {
          log.line("PASS " <> name)
          run_suites(rest, failures)
        }
        Error(Failure(message)) -> {
          log.line("FAIL " <> name <> ": " <> message)
          run_suites(rest, [Failure(name <> ": " <> message), ..failures])
        }
      }
    }
  }
}
