-module(atomvm_gleam_adc_ffi).
-export([
    init/0,
    deinit/1,
    acquire/4,
    acquire_default/2,
    release_channel/1,
    sample/2,
    sample_with/5,
    start/0,
    start_pin/1,
    start_pin_with/3,
    read/1,
    read_with/4,
    stop_pin/1,
    stop/0
]).

init() ->
    wrap_value(esp_adc:init()).

deinit(Unit) ->
    wrap_ok(esp_adc:deinit(Unit)).

acquire(Pin, Unit, BitWidth, Attenuation) ->
    wrap_value(esp_adc:acquire(Pin, Unit, BitWidth, Attenuation)).

acquire_default(Pin, Unit) ->
    wrap_value(esp_adc:acquire(Pin, Unit)).

release_channel(Channel) ->
    wrap_ok(esp_adc:release_channel(Channel)).

sample(Channel, Unit) ->
    wrap_reading(esp_adc:sample(Channel, Unit)).

sample_with(Channel, Unit, Raw, Voltage, Samples) ->
    wrap_reading(esp_adc:sample(Channel, Unit, read_options(Raw, Voltage, Samples))).

start() ->
    try_value(fun() -> esp_adc:start() end).

start_pin(Pin) ->
    try_ok(fun() -> esp_adc:start(Pin) end).

start_pin_with(Pin, BitWidth, Attenuation) ->
    try_ok(fun() ->
        esp_adc:start(Pin, [{bitwidth, BitWidth}, {atten, Attenuation}])
    end).

read(Pin) ->
    try_reading(fun() -> esp_adc:read(Pin) end).

read_with(Pin, Raw, Voltage, Samples) ->
    try_reading(fun() ->
        esp_adc:read(Pin, read_options(Raw, Voltage, Samples))
    end).

stop_pin(Pin) ->
    try_ok(fun() -> esp_adc:stop(Pin) end).

stop() ->
    try_ok(fun() -> esp_adc:stop() end).

read_options(Raw, Voltage, Samples) ->
    Options = [{samples, Samples}],
    Options1 = case Raw of
        true -> [raw | Options];
        false -> Options
    end,
    case Voltage of
        true -> [voltage | Options1];
        false -> Options1
    end.

try_value(Fun) ->
    try Fun() of
        Result -> wrap_value(Result)
    catch
        throw:Reason -> wrap_thrown(Reason);
        error:Reason -> wrap_thrown(Reason)
    end.

try_ok(Fun) ->
    try Fun() of
        Result -> wrap_ok(Result)
    catch
        throw:Reason -> wrap_thrown(Reason);
        error:Reason -> wrap_thrown(Reason)
    end.

try_reading(Fun) ->
    try Fun() of
        Result -> wrap_reading(Result)
    catch
        throw:Reason -> wrap_thrown(Reason);
        error:Reason -> wrap_thrown(Reason)
    end.

wrap_thrown({error, Reason}) ->
    wrap_reason(Reason);
wrap_thrown(Reason) ->
    wrap_reason(Reason).

wrap_reading({ok, {Raw, Millivolts}}) ->
    {ok, {field(Raw), field(Millivolts)}};
wrap_reading(error) ->
    {error, failed};
wrap_reading({error, Reason}) ->
    wrap_reason(Reason).

field(undefined) ->
    none;
field(Value) ->
    {some, Value}.

wrap_value({ok, Value}) ->
    {ok, Value};
wrap_value(error) ->
    {error, failed};
wrap_value({error, Reason}) ->
    wrap_reason(Reason).

wrap_ok(ok) ->
    {ok, nil};
wrap_ok(error) ->
    {error, failed};
wrap_ok({error, Reason}) ->
    wrap_reason(Reason).

%% Map AtomVM `{error, Reason}` onto Gleam `Error` constructors.
%% Known atoms pass through as zero-arity variants; anything else is `Other`.
wrap_reason(not_supported) ->
    {error, not_supported};
wrap_reason(badarg) ->
    {error, badarg};
wrap_reason(timeout) ->
    {error, timeout};
wrap_reason(failed) ->
    {error, failed};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
