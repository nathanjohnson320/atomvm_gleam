import atomvm_gleam/spi.{type Spi}

/// Opaque handle for an AtomGL `display` port, opened via
/// `erlang:open_port({spawn, <<"display">>}, Opts)`.
///
/// See [`erlang:open_port/2`](https://doc.atomvm.org/latest/apidocs/erlang/estdlib/erlang.html#open-port-2).
pub type Display

/// Backlight active level (`low` / `high`), matching AtomGL port options.
pub type ActiveLevel {
  Low
  High
}

/// Options passed to the AtomGL `display` port.
///
/// Built into the Erlang proplist expected by
/// [`erlang:open_port/2`](https://doc.atomvm.org/latest/apidocs/erlang/estdlib/erlang.html#open-port-2)
/// with `{spawn, <<"display">>}`.
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
    spi_host: Spi,
  )
}

/// Open the AtomGL display port with the given options. Pin and panel values
/// stay in the application so each workshop exercise shows the wiring.
///
/// See [`erlang:open_port/2`](https://doc.atomvm.org/latest/apidocs/erlang/estdlib/erlang.html#open-port-2).
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
    spi_host,
  )
}

/// Push a display list to the panel. Item types are scene-specific and pass
/// through as Erlang terms AtomGL already understands (`{update, Items}`).
///
/// See [`port:call/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/port.html#call-2).
pub fn update(display: Display, items: List(a)) -> Nil {
  update_ffi(display, items)
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
  spi_host: Spi,
) -> Display

@external(erlang, "atomvm_gleam_display_ffi", "update")
fn update_ffi(display: Display, items: List(a)) -> Nil
