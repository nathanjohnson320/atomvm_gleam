//// Typed Gleam wrappers for the [AtomGL](https://github.com/atomvm/atomgl)
//// `display` port driver (ESP32 component; not part of AtomVM core).
////
//// Options and wiring: [display drivers](https://github.com/atomvm/atomgl/blob/main/docs/display-drivers.md).
//// Display-list primitives: [primitives](https://github.com/atomvm/atomgl/blob/main/docs/primitives.md).
//// Overview: [AtomGL README](https://github.com/atomvm/atomgl/blob/main/README.Md).
////
//// The port is opened with `erlang:open_port({spawn, <<"display">>}, Opts)` and
//// driven with `port:call/2`; those are transport only - semantics live in AtomGL.

import atomvm_gleam/spi.{type Spi}
import gleam/option.{type Option}

/// Opaque handle for an AtomGL `display` port.
///
/// See [AtomGL display drivers](https://github.com/atomvm/atomgl/blob/main/docs/display-drivers.md).
pub type Display

/// Backlight active level (`low` / `high`), matching AtomGL port options.
pub type ActiveLevel {
  Low
  High
}

/// Options passed to the AtomGL `display` port.
///
/// Built into the Erlang proplist for
/// `erlang:open_port({spawn, <<"display">>}, Opts)`. Field meanings match
/// [AtomGL display drivers](https://github.com/atomvm/atomgl/blob/main/docs/display-drivers.md)
/// (`compatible`, pins, backlight, `spi_host`, etc.).
///
/// `clock_speed_hz` is optional; omit it (`None`) to keep AtomGL's panel default.
pub type Config {
  Config(
    compatible: String,
    init_seq_type: String,
    enable_tft_invon: Bool,
    width: Int,
    height: Int,
    rotation: Int,
    reset: Int,
    dc: Int,
    cs: Int,
    backlight: Int,
    backlight_active: ActiveLevel,
    backlight_enabled: Bool,
    clock_speed_hz: Option(Int),
    spi_host: Spi,
  )
}

/// Open the AtomGL display port with the given options. Pin and panel values
/// stay in the application so each workshop exercise shows the wiring.
///
/// See [AtomGL display drivers](https://github.com/atomvm/atomgl/blob/main/docs/display-drivers.md).
pub fn open(config: Config) -> Display {
  let Config(
    compatible:,
    init_seq_type:,
    enable_tft_invon:,
    width:,
    height:,
    rotation:,
    reset:,
    dc:,
    cs:,
    backlight:,
    backlight_active:,
    backlight_enabled:,
    clock_speed_hz:,
    spi_host:,
  ) = config
  open_ffi(
    compatible,
    init_seq_type,
    enable_tft_invon,
    width,
    height,
    rotation,
    reset,
    dc,
    cs,
    backlight,
    backlight_active,
    backlight_enabled,
    clock_speed_hz,
    spi_host,
  )
}

/// Push a display list to the panel via `{update, Items}`.
///
/// Common item shapes include `text`, `rect`, `image` (`rgba8888`), and
/// `scaled_cropped_image`. Each update replaces the previous list.
///
/// See [AtomGL primitives](https://github.com/atomvm/atomgl/blob/main/docs/primitives.md).
pub fn update(display: Display, items: List(a)) -> Nil {
  update_ffi(display, items)
}

/// Register a font binary under `name` for later `{text, …}` items
/// (`{register_font, Name, Bytes}`).
///
/// `name` is turned into an Erlang atom (for example `"dogica"` → `dogica`).
/// Font registration is implemented in AtomGL; it is not covered in the
/// markdown driver docs - see the [AtomGL](https://github.com/atomvm/atomgl) sources.
pub fn register_font(display: Display, name: String, bytes: BitArray) -> Nil {
  register_font_ffi(display, name, bytes)
}

/// Release a previously registered font (`{deregister_font, Name}`).
///
/// See the [AtomGL](https://github.com/atomvm/atomgl) sources (not in the
/// markdown driver docs).
pub fn deregister_font(display: Display, name: String) -> Nil {
  deregister_font_ffi(display, name)
}

@external(erlang, "atomvm_gleam_display_ffi", "open")
fn open_ffi(
  compatible: String,
  init_seq_type: String,
  enable_tft_invon: Bool,
  width: Int,
  height: Int,
  rotation: Int,
  reset: Int,
  dc: Int,
  cs: Int,
  backlight: Int,
  backlight_active: ActiveLevel,
  backlight_enabled: Bool,
  clock_speed_hz: Option(Int),
  spi_host: Spi,
) -> Display

@external(erlang, "atomvm_gleam_display_ffi", "update")
fn update_ffi(display: Display, items: List(a)) -> Nil

@external(erlang, "atomvm_gleam_display_ffi", "register_font")
fn register_font_ffi(display: Display, name: String, bytes: BitArray) -> Nil

@external(erlang, "atomvm_gleam_display_ffi", "deregister_font")
fn deregister_font_ffi(display: Display, name: String) -> Nil
