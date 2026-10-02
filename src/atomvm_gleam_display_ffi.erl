-module(atomvm_gleam_display_ffi).
-export([open/13, update/2]).

open(
    Compatible,
    InitSeqType,
    EnableTftInvon,
    Width,
    Height,
    Rotation,
    Reset,
    Dc,
    Cs,
    Backlight,
    BacklightActive,
    BacklightEnabled,
    Spi
) ->
    erlang:open_port({spawn, <<"display">>}, [
        {compatible, Compatible},
        {init_seq_type, InitSeqType},
        {enable_tft_invon, EnableTftInvon},
        {width, Width},
        {height, Height},
        {rotation, Rotation},
        {reset, Reset},
        {dc, Dc},
        {cs, Cs},
        {backlight, Backlight},
        {backlight_active, BacklightActive},
        {backlight_enabled, BacklightEnabled},
        {spi_host, Spi}
    ]).

update(Display, Items) ->
    ok = port:call(Display, {update, Items}),
    nil.
