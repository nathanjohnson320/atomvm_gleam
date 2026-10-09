import atomvm_gleam/spi.{type Spi}
import gleam/option.{type Option}

/// Opaque handle for an AtomGL `display` port, opened via
/// `erlang:open_port({spawn, <<"display">>}, Opts)`.
///
/// See [`erlang:open_port/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/erlang.html#open-port-2).
pub type Display

/// Backlight active level (`low` / `high`), matching AtomGL port options.
pub type ActiveLevel {
  Low
  High
}

/// Options passed to the AtomGL `display` port.
///
/// Built into the Erlang proplist expected by
/// [`erlang:open_port/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/erlang.html#open-port-2)
/// with `{spawn, <<"display">>}`.
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
/// See [`erlang:open_port/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/erlang.html#open-port-2).
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

/// Push a display list to the panel. Item types are scene-specific and pass
/// through as Erlang terms AtomGL already understands (`{update, Items}`).
/// Common shapes include `text`, `rect`, `image` (`rgba8888`), and
/// `scaled_cropped_image`.
///
/// See [`port:call/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/port.html#call-2).
pub fn update(display: Display, items: List(a)) -> Nil {
  update_ffi(display, items)
}

/// Register a font binary under `name` for later `{text, …}` items.
///
/// `name` is turned into an Erlang atom (for example `"dogica"` → `dogica`).
///
/// See [`port:call/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/port.html#call-2).
pub fn register_font(display: Display, name: String, bytes: BitArray) -> Nil {
  register_font_ffi(display, name, bytes)
}

/// Release a previously registered font.
///
/// See [`port:call/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/port.html#call-2).
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
