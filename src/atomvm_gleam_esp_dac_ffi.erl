-module(atomvm_gleam_esp_dac_ffi).
-export([
    new_channel/1,
    oneshot_output_voltage/2,
    oneshot_del_channel/1
]).

new_channel(ChanId) ->
    try_value(fun() ->
        esp_dac:new_channel(oneshot, [{chan_id, ChanId}])
    end).

oneshot_output_voltage(Channel, Level) ->
    try_ok(fun() ->
        esp_dac:oneshot_output_voltage(Channel, Level)
    end).

oneshot_del_channel(Channel) ->
    try_ok(fun() ->
        esp_dac:oneshot_del_channel(Channel)
    end).

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

wrap_thrown({error, Reason}) ->
    wrap_reason(Reason);
wrap_thrown(Reason) ->
    wrap_reason(Reason).

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
