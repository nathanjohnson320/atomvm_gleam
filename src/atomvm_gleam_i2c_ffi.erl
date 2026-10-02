-module(atomvm_gleam_i2c_ffi).
-export([open/3, close/1, read_bytes/4, write_bytes/4]).

open(Scl, Sda, ClockSpeedHz) ->
    try
        Bus = i2c:open([
            {scl, Scl},
            {sda, Sda},
            {clock_speed_hz, ClockSpeedHz}
        ]),
        {ok, Bus}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

close(Bus) ->
    wrap_ok(i2c:close(Bus)).

read_bytes(Bus, Address, Register, Count) ->
    wrap_value(i2c:read_bytes(Bus, Address, Register, Count)).

write_bytes(Bus, Address, Register, Data) ->
    wrap_ok(i2c:write_bytes(Bus, Address, Register, Data)).

wrap_ok(ok) ->
    {ok, nil};
wrap_ok(error) ->
    {error, failed};
wrap_ok({error, Reason}) ->
    wrap_reason(Reason).

wrap_value({ok, Value}) ->
    {ok, Value};
wrap_value(error) ->
    {error, failed};
wrap_value({error, Reason}) ->
    wrap_reason(Reason).

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
