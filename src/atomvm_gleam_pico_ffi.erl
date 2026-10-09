-module(atomvm_gleam_pico_ffi).
-export([
    cyw43_arch_gpio_get/1,
    cyw43_arch_gpio_put/2,
    rtc_set_datetime/6
]).

cyw43_arch_gpio_get(Gpio) ->
    try
        Level = pico:cyw43_arch_gpio_get(Gpio),
        {ok, Level}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

cyw43_arch_gpio_put(Gpio, Level) ->
    try
        wrap_ok(pico:cyw43_arch_gpio_put(Gpio, level_int(Level)))
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

rtc_set_datetime(Year, Month, Day, Hour, Minute, Second) ->
    try
        wrap_ok(pico:rtc_set_datetime({{Year, Month, Day}, {Hour, Minute, Second}}))
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

%% Map Gleam `PinHigh` / `PinLow` onto upstream CYW43 levels `1` / `0`.
level_int(pin_high) ->
    1;
level_int(pin_low) ->
    0.

wrap_ok(ok) ->
    {ok, nil};
wrap_ok(error) ->
    {error, failed};
wrap_ok({error, Reason}) ->
    wrap_reason(Reason).

%% Map AtomVM `{error, Reason}` atoms onto Gleam `Error` constructors.
%% Known atoms pass through as zero-arity variants; anything else is `Other`.
wrap_reason(not_supported) ->
    {error, not_supported};
wrap_reason(badarg) ->
    {error, badarg};
wrap_reason(timeout) ->
    {error, timeout};
wrap_reason(failed) ->
    {error, failed};
wrap_reason(undef) ->
    {error, not_supported};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
