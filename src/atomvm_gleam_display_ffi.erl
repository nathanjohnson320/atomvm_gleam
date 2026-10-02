-module(atomvm_gleam_display_ffi).
-export([open/14, update/2, register_font/3, deregister_font/2]).

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
    ClockSpeedHz,
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
        | opt(clock_speed_hz, ClockSpeedHz)
    ]).

update(Display, Items) ->
    ok = port:call(Display, {update, Items}),
    nil.

register_font(Display, Name, Bytes) ->
    ok = port:call(Display, {register_font, name_atom(Name), Bytes}),
    nil.

deregister_font(Display, Name) ->
    ok = port:call(Display, {deregister_font, name_atom(Name)}),
    nil.

opt(_Key, none) ->
    [];
opt(Key, {some, Value}) ->
    [{Key, Value}].

name_atom(Name) when is_binary(Name) ->
    binary_to_atom(Name, utf8);
name_atom(Name) when is_atom(Name) ->
    Name.
