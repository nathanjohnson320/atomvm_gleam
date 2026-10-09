/// UART driver wrappers for AtomVM.
///
/// Peripheral `name` strings accepted by [`open`](#open) include `"UART0"`,
/// `"UART1"`, `"UART2"`, and on ESP32 chips with built-in USB-Serial-JTAG,
/// [`usb_serial_jtag_name`](#usb_serial_jtag_name) (`"USB_SERIAL_JTAG"`).
/// RP2/STM32 USB CDC is a separate `usb_cdc` module, not this one.
///
/// Source: [`libs/avm_esp32/src/uart.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/uart.erl).
/// Edoc: [`uart_hal`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/uart_hal.html).
import gleam/option.{type Option}

/// Opaque UART driver handle (`pid()` from `uart:open/2`).
pub type Uart

/// Errors from the UART driver.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Ealready
  Other(String)
}

/// Flow control mode.
pub type FlowControl {
  NoFlow
  Hardware
  Software
}

/// Parity mode.
pub type Parity {
  NoParity
  Even
  Odd
}

/// Options for [`open`](#open) / [`open_default`](#open_default).
///
/// See [`uart.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/uart.erl)
/// and [`uart_hal`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/uart_hal.html).
pub type Config {
  Config(
    tx: Option(Int),
    rx: Option(Int),
    rts: Option(Int),
    cts: Option(Int),
    speed: Option(Int),
    data_bits: Option(Int),
    stop_bits: Option(Int),
    event_queue_len: Option(Int),
    flow_control: Option(FlowControl),
    parity: Option(Parity),
  )
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    Ealready -> "ealready"
    Other(reason) -> reason
  }
}

/// Empty config (driver defaults).
pub fn default_config() -> Config {
  Config(
    tx: option.None,
    rx: option.None,
    rts: option.None,
    cts: option.None,
    speed: option.None,
    data_bits: option.None,
    stop_bits: option.None,
    event_queue_len: option.None,
    flow_control: option.None,
    parity: option.None,
  )
}

/// Peripheral name for ESP32 USB-Serial-JTAG (`"USB_SERIAL_JTAG"`).
///
/// Pass to [`open`](#open) on chips that expose the built-in USB-Serial-JTAG
/// peripheral (for example ESP32-C3/C5/C6/C61/H2/S3/P4).
///
/// See [`uart.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/uart.erl)
/// and [`uart_hal`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/uart_hal.html).
pub fn usb_serial_jtag_name() -> String {
  "USB_SERIAL_JTAG"
}

/// Open a named UART peripheral (`"UART0"` / `"UART1"` / `"UART2"` /
/// `"USB_SERIAL_JTAG"`).
///
/// See [`uart:open/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/uart.erl)
/// and [`uart_hal`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/uart_hal.html).
pub fn open(name: String, config: Config) -> Result(Uart, Error) {
  let Config(
    tx:,
    rx:,
    rts:,
    cts:,
    speed:,
    data_bits:,
    stop_bits:,
    event_queue_len:,
    flow_control:,
    parity:,
  ) = config
  open_ffi(
    name,
    tx,
    rx,
    rts,
    cts,
    speed,
    data_bits,
    stop_bits,
    event_queue_len,
    flow_control,
    parity,
  )
}

/// Open the default UART with the given options.
///
/// See [`uart:open/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/uart.erl)
/// and [`uart_hal`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/uart_hal.html).
pub fn open_default(config: Config) -> Result(Uart, Error) {
  let Config(
    tx:,
    rx:,
    rts:,
    cts:,
    speed:,
    data_bits:,
    stop_bits:,
    event_queue_len:,
    flow_control:,
    parity:,
  ) = config
  open_default_ffi(
    tx,
    rx,
    rts,
    cts,
    speed,
    data_bits,
    stop_bits,
    event_queue_len,
    flow_control,
    parity,
  )
}

/// Write data to the UART.
///
/// See [`uart:write/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/uart.erl).
@external(erlang, "atomvm_gleam_uart_ffi", "write")
pub fn write(uart: Uart, data: BitArray) -> Result(Nil, Error)

/// Read available data, waiting up to `timeout_ms`.
///
/// See [`uart:read/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/uart.erl).
@external(erlang, "atomvm_gleam_uart_ffi", "read")
pub fn read(uart: Uart, timeout_ms: Int) -> Result(BitArray, Error)

/// Close the UART driver.
///
/// See [`uart:close/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/uart.erl).
@external(erlang, "atomvm_gleam_uart_ffi", "close")
pub fn close(uart: Uart) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_uart_ffi", "open")
fn open_ffi(
  name: String,
  tx: Option(Int),
  rx: Option(Int),
  rts: Option(Int),
  cts: Option(Int),
  speed: Option(Int),
  data_bits: Option(Int),
  stop_bits: Option(Int),
  event_queue_len: Option(Int),
  flow_control: Option(FlowControl),
  parity: Option(Parity),
) -> Result(Uart, Error)

@external(erlang, "atomvm_gleam_uart_ffi", "open_default")
fn open_default_ffi(
  tx: Option(Int),
  rx: Option(Int),
  rts: Option(Int),
  cts: Option(Int),
  speed: Option(Int),
  data_bits: Option(Int),
  stop_bits: Option(Int),
  event_queue_len: Option(Int),
  flow_control: Option(FlowControl),
  parity: Option(Parity),
) -> Result(Uart, Error)
