import atomvm_gleam/crypto
import atomvm_gleam/gpio
import atomvm_gleam/http_server
import atomvm_gleam/ledc
import atomvm_gleam/network
import atomvm_gleam/ssl
import atomvm_gleam/uart
import atomvm_gleam/usb_cdc
import gleam/erlang/atom

pub fn crypto_encrypt_opts_test() {
  // COVER: crypto.encrypt_opts
  let opts = crypto.encrypt_opts()
  assert opts.encrypt == True
}

pub fn crypto_decrypt_opts_test() {
  // COVER: crypto.decrypt_opts
  let opts = crypto.decrypt_opts()
  assert opts.encrypt == False
}

pub fn gpio_pin_wl_test() {
  // COVER: gpio.pin
  assert gpio.pin(4) == gpio.PinNum(4)
  // COVER: gpio.wl
  assert gpio.wl(0) == gpio.WlPin(0)
}

pub fn ledc_speed_modes_test() {
  // COVER: ledc.high_speed_mode
  let high = ledc.high_speed_mode()
  // COVER: ledc.low_speed_mode
  let low = ledc.low_speed_mode()
  assert high != low
}

pub fn uart_defaults_test() {
  // COVER: uart.default_config
  let cfg = uart.default_config()
  let _ = cfg
  // COVER: uart.usb_serial_jtag_name
  assert uart.usb_serial_jtag_name() == "USB_SERIAL_JTAG"
}

pub fn usb_cdc_default_config_test() {
  // COVER: usb_cdc.default_config
  let _cfg = usb_cdc.default_config()
  assert usb_cdc.error_to_string(usb_cdc.Failed) == "error"
}

pub fn ssl_default_options_test() {
  // COVER: ssl.default_options
  let _opts = ssl.default_options()
  assert ssl.error_to_string(ssl.Failed) == "error"
}

pub fn network_sta_status_to_string_test() {
  // COVER: network.sta_status_to_string
  assert network.sta_status_to_string(network.StaConnected) == "connected"
  assert network.sta_status_to_string(network.StaInactive) == "inactive"
}

pub fn http_server_route_test() {
  // COVER: http_server.route
  let r = http_server.route("/", atom.create("handler"))
  assert r.path == "/"
}
