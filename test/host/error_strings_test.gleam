import atomvm_gleam/adc
import atomvm_gleam/atomvm
import atomvm_gleam/avm_pubsub
import atomvm_gleam/console
import atomvm_gleam/crypto
import atomvm_gleam/emscripten
import atomvm_gleam/emscripten_websocket
import atomvm_gleam/esp
import atomvm_gleam/esp_dac
import atomvm_gleam/gpio
import atomvm_gleam/http
import atomvm_gleam/http_server
import atomvm_gleam/i2c
import atomvm_gleam/json
import atomvm_gleam/ledc
import atomvm_gleam/mdns
import atomvm_gleam/network
import atomvm_gleam/pico
import atomvm_gleam/spi
import atomvm_gleam/ssl
import atomvm_gleam/uart
import atomvm_gleam/usb_cdc
import atomvm_gleam/websocket

pub fn atomvm_error_to_string_test() {
  // COVER: atomvm.error_to_string
  assert atomvm.error_to_string(atomvm.Failed) == "error"
  assert atomvm.error_to_string(atomvm.NotSupported) == "not_supported"
  assert atomvm.error_to_string(atomvm.Badarg) == "badarg"
  assert atomvm.error_to_string(atomvm.Timeout) == "timeout"
  assert atomvm.error_to_string(atomvm.NotFound) == "not_found"
  assert atomvm.error_to_string(atomvm.Undefined) == "undefined"
  assert atomvm.error_to_string(atomvm.Other("x")) == "x"
}

pub fn console_error_to_string_test() {
  // COVER: console.error_to_string
  assert console.error_to_string(console.Failed) == "error"
  assert console.error_to_string(console.NotSupported) == "not_supported"
  assert console.error_to_string(console.Badarg) == "badarg"
  assert console.error_to_string(console.Timeout) == "timeout"
  assert console.error_to_string(console.Other("boom")) == "boom"
}

pub fn crypto_error_to_string_test() {
  // COVER: crypto.error_to_string
  assert crypto.error_to_string(crypto.Failed) == "error"
  assert crypto.error_to_string(crypto.NotSupported) == "not_supported"
  assert crypto.error_to_string(crypto.Badarg) == "badarg"
  assert crypto.error_to_string(crypto.Timeout) == "timeout"
  assert crypto.error_to_string(crypto.Other("x")) == "x"
}

pub fn json_error_to_string_test() {
  // COVER: json.error_to_string
  assert json.error_to_string(json.Failed) == "error"
  assert json.error_to_string(json.Badarg) == "badarg"
  assert json.error_to_string(json.Other("x")) == "x"
}

pub fn gpio_error_to_string_test() {
  // COVER: gpio.error_to_string
  assert gpio.error_to_string(gpio.Failed) == "error"
  assert gpio.error_to_string(gpio.NotSupported) == "not_supported"
  assert gpio.error_to_string(gpio.Badarg) == "badarg"
  assert gpio.error_to_string(gpio.Timeout) == "timeout"
  assert gpio.error_to_string(gpio.Other("x")) == "x"
}

pub fn esp_error_to_string_test() {
  // COVER: esp.error_to_string
  assert esp.error_to_string(esp.Failed) == "error"
  assert esp.error_to_string(esp.NotSupported) == "not_supported"
  assert esp.error_to_string(esp.Badarg) == "badarg"
  assert esp.error_to_string(esp.Timeout) == "timeout"
  assert esp.error_to_string(esp.NotFound) == "not_found"
  assert esp.error_to_string(esp.Other("x")) == "x"
}

pub fn pico_error_to_string_test() {
  // COVER: pico.error_to_string
  assert pico.error_to_string(pico.Failed) == "error"
  assert pico.error_to_string(pico.NotSupported) == "not_supported"
  assert pico.error_to_string(pico.Badarg) == "badarg"
  assert pico.error_to_string(pico.Timeout) == "timeout"
  assert pico.error_to_string(pico.Other("x")) == "x"
}

pub fn emscripten_error_to_string_test() {
  // COVER: emscripten.error_to_string
  assert emscripten.error_to_string(emscripten.Failed) == "error"
  assert emscripten.error_to_string(emscripten.NotSupported) == "not_supported"
  assert emscripten.error_to_string(emscripten.Badarg) == "badarg"
  assert emscripten.error_to_string(emscripten.Timeout) == "timeout"
  assert emscripten.error_to_string(emscripten.InvalidTarget)
    == "invalid_target"
  assert emscripten.error_to_string(emscripten.UnknownTarget)
    == "unknown_target"
  assert emscripten.error_to_string(emscripten.FailedNotDeferred)
    == "failed_not_deferred"
  assert emscripten.error_to_string(emscripten.NoData) == "no_data"
  assert emscripten.error_to_string(emscripten.TimedOut) == "timed_out"
  assert emscripten.error_to_string(emscripten.Code(7)) == "code:7"
  assert emscripten.error_to_string(emscripten.Other("x")) == "x"
}

pub fn emscripten_websocket_error_to_string_test() {
  // COVER: emscripten_websocket.error_to_string
  assert emscripten_websocket.error_to_string(emscripten_websocket.Failed)
    == "error"
  assert emscripten_websocket.error_to_string(emscripten_websocket.NotSupported)
    == "not_supported"
  assert emscripten_websocket.error_to_string(emscripten_websocket.NotOwner)
    == "not_owner"
  assert emscripten_websocket.error_to_string(emscripten_websocket.SocketClosed)
    == "closed"
  assert emscripten_websocket.error_to_string(emscripten_websocket.Other("x"))
    == "x"
}

pub fn avm_pubsub_error_to_string_test() {
  // COVER: avm_pubsub.error_to_string
  assert avm_pubsub.error_to_string(avm_pubsub.Failed) == "error"
  assert avm_pubsub.error_to_string(avm_pubsub.NotSupported) == "not_supported"
  assert avm_pubsub.error_to_string(avm_pubsub.Other("x")) == "x"
}

pub fn adc_error_to_string_test() {
  // COVER: adc.error_to_string
  assert adc.error_to_string(adc.Failed) == "error"
  assert adc.error_to_string(adc.NotSupported) == "not_supported"
  assert adc.error_to_string(adc.Other("x")) == "x"
}

pub fn esp_dac_error_to_string_test() {
  // COVER: esp_dac.error_to_string
  assert esp_dac.error_to_string(esp_dac.Failed) == "error"
  assert esp_dac.error_to_string(esp_dac.NotSupported) == "not_supported"
  assert esp_dac.error_to_string(esp_dac.Other("x")) == "x"
}

pub fn ledc_error_to_string_test() {
  // COVER: ledc.error_to_string
  assert ledc.error_to_string(ledc.Failed) == "error"
  assert ledc.error_to_string(ledc.NotSupported) == "not_supported"
  assert ledc.error_to_string(ledc.Other("x")) == "x"
}

pub fn i2c_error_to_string_test() {
  // COVER: i2c.error_to_string
  assert i2c.error_to_string(i2c.Failed) == "error"
  assert i2c.error_to_string(i2c.NotSupported) == "not_supported"
  assert i2c.error_to_string(i2c.Other("x")) == "x"
}

pub fn spi_error_to_string_test() {
  // COVER: spi.error_to_string
  assert spi.error_to_string(spi.Failed) == "error"
  assert spi.error_to_string(spi.NotSupported) == "not_supported"
  assert spi.error_to_string(spi.Other("x")) == "x"
}

pub fn uart_error_to_string_test() {
  // COVER: uart.error_to_string
  assert uart.error_to_string(uart.Failed) == "error"
  assert uart.error_to_string(uart.NotSupported) == "not_supported"
  assert uart.error_to_string(uart.Other("x")) == "x"
}

pub fn usb_cdc_error_to_string_test() {
  // COVER: usb_cdc.error_to_string
  assert usb_cdc.error_to_string(usb_cdc.Failed) == "error"
  assert usb_cdc.error_to_string(usb_cdc.NotSupported) == "not_supported"
  assert usb_cdc.error_to_string(usb_cdc.Other("x")) == "x"
}

pub fn network_error_to_string_test() {
  // COVER: network.error_to_string
  assert network.error_to_string(network.Failed) == "error"
  assert network.error_to_string(network.NotSupported) == "not_supported"
  assert network.error_to_string(network.Disconnected) == "disconnected"
  assert network.error_to_string(network.Other("x")) == "x"
}

pub fn ssl_error_to_string_test() {
  // COVER: ssl.error_to_string
  assert ssl.error_to_string(ssl.Failed) == "error"
  assert ssl.error_to_string(ssl.NotSupported) == "not_supported"
  assert ssl.error_to_string(ssl.Other("x")) == "x"
}

pub fn http_error_to_string_test() {
  // COVER: http.error_to_string
  assert http.error_to_string(http.Failed) == "error"
  assert http.error_to_string(http.NotSupported) == "not_supported"
  assert http.error_to_string(http.Other("x")) == "x"
}

pub fn http_server_error_to_string_test() {
  // COVER: http_server.error_to_string
  assert http_server.error_to_string(http_server.Failed) == "error"
  assert http_server.error_to_string(http_server.NotSupported)
    == "not_supported"
  assert http_server.error_to_string(http_server.Other("x")) == "x"
}

pub fn websocket_error_to_string_test() {
  // COVER: websocket.error_to_string
  assert websocket.error_to_string(websocket.Failed) == "error"
  assert websocket.error_to_string(websocket.NotSupported) == "not_supported"
  assert websocket.error_to_string(websocket.Other("x")) == "x"
}

pub fn mdns_error_to_string_test() {
  // COVER: mdns.error_to_string
  assert mdns.error_to_string(mdns.Failed) == "error"
  assert mdns.error_to_string(mdns.NotSupported) == "not_supported"
  assert mdns.error_to_string(mdns.Other("x")) == "x"
}
