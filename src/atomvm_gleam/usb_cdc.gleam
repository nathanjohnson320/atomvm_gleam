/// USB CDC ACM driver wrappers for AtomVM (ESP32 / RP2 / STM32).
///
/// Peripheral `name` strings accepted by [`open`](#open) differ by platform:
///
/// - **ESP32:** CDC interface id such as `"CDC0"` or `"USB0"` (default CDC 0
///   when using [`open_default`](#open_default)).
/// - **RP2 / STM32:** the name is ignored (single CDC interface); prefer
///   [`open_default`](#open_default).
///
/// Upstream (same export shape on each platform):
/// [ESP32](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/usb_cdc.erl),
/// [RP2](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/usb_cdc.erl),
/// [STM32](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_stm32/src/usb_cdc.erl).
/// Implements the
/// [`uart_hal`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/uart_hal.html)
/// behaviour over USB CDC.
/// Opaque USB CDC driver handle (`port()` from `usb_cdc:open/1` / `open/2`).
pub type UsbCdc

/// Errors from the USB CDC driver.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Ealready
  Other(String)
}

/// Options for [`open`](#open) / [`open_default`](#open_default).
///
/// Currently unused by the AtomVM USB CDC drivers; pass
/// [`default_config`](#default_config). Reserved for future driver options.
pub type Config {
  Config
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
  Config
}

/// Open a named USB CDC interface (`"CDC0"` / `"USB0"` on ESP32).
///
/// On RP2 and STM32 the name is ignored (single CDC interface).
///
/// See `usb_cdc:open/2` on
/// [ESP32](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/usb_cdc.erl),
/// [RP2](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/usb_cdc.erl),
/// [STM32](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_stm32/src/usb_cdc.erl).
pub fn open(name: String, _config: Config) -> Result(UsbCdc, Error) {
  open_ffi(name)
}

/// Open the default USB CDC interface with the given options.
///
/// On ESP32 this opens CDC interface 0 when no peripheral is specified.
/// On RP2 / STM32 this opens the single CDC interface.
///
/// See `usb_cdc:open/1` on
/// [ESP32](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/usb_cdc.erl),
/// [RP2](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_rp2/src/usb_cdc.erl),
/// [STM32](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_stm32/src/usb_cdc.erl).
pub fn open_default(_config: Config) -> Result(UsbCdc, Error) {
  open_default_ffi()
}

/// Write data to the USB CDC interface.
///
/// See `usb_cdc:write/2`.
@external(erlang, "atomvm_gleam_usb_cdc_ffi", "write")
pub fn write(usb: UsbCdc, data: BitArray) -> Result(Nil, Error)

/// Read available data, waiting up to `timeout_ms`.
///
/// See `usb_cdc:read/2`.
@external(erlang, "atomvm_gleam_usb_cdc_ffi", "read")
pub fn read(usb: UsbCdc, timeout_ms: Int) -> Result(BitArray, Error)

/// Read data, blocking until bytes are available.
///
/// See `usb_cdc:read/1`.
@external(erlang, "atomvm_gleam_usb_cdc_ffi", "read_blocking")
pub fn read_blocking(usb: UsbCdc) -> Result(BitArray, Error)

/// Close the USB CDC driver.
///
/// See `usb_cdc:close/1`.
@external(erlang, "atomvm_gleam_usb_cdc_ffi", "close")
pub fn close(usb: UsbCdc) -> Result(Nil, Error)

@external(erlang, "atomvm_gleam_usb_cdc_ffi", "open")
fn open_ffi(name: String) -> Result(UsbCdc, Error)

@external(erlang, "atomvm_gleam_usb_cdc_ffi", "open_default")
fn open_default_ffi() -> Result(UsbCdc, Error)
