%% FFI for atomvm_gleam/emscripten_websocket.
%% Calls upstream Erlang module `websocket` (avm_emscripten, browser only).
-module(atomvm_gleam_emscripten_websocket_ffi).
-export([
    is_supported/0,
    new_1/1,
    new_2/2,
    new_3/3,
    controlling_process/2,
    ready_state/1,
    buffered_amount/1,
    url/1,
    extensions/1,
    protocol/1,
    send_utf8/2,
    send_binary/2,
    close_1/1,
    close_2/2,
    close_3/3
]).

is_supported() ->
    try
        websocket:is_supported()
    catch
        error:undef ->
            false;
        _:_ ->
            false
    end.

new_1(Url) ->
    wrap_value(fun() -> websocket:new(Url) end).

new_2(Url, Protocols) ->
    wrap_value(fun() -> websocket:new(Url, Protocols) end).

new_3(Url, Protocols, Owner) ->
    wrap_value(fun() -> websocket:new(Url, Protocols, Owner) end).

controlling_process(Ws, Owner) ->
    wrap_call(fun() -> websocket:controlling_process(Ws, Owner) end).

ready_state(Ws) ->
    wrap_value(fun() -> websocket:ready_state(Ws) end).

buffered_amount(Ws) ->
    wrap_value(fun() -> websocket:buffered_amount(Ws) end).

url(Ws) ->
    wrap_chardata(fun() -> websocket:url(Ws) end).

extensions(Ws) ->
    wrap_chardata(fun() -> websocket:extensions(Ws) end).

protocol(Ws) ->
    wrap_chardata(fun() -> websocket:protocol(Ws) end).

send_utf8(Ws, Text) ->
    wrap_call(fun() -> websocket:send_utf8(Ws, Text) end).

send_binary(Ws, Data) ->
    wrap_call(fun() -> websocket:send_binary(Ws, Data) end).

close_1(Ws) ->
    wrap_call(fun() -> websocket:close(Ws) end).

close_2(Ws, StatusCode) ->
    wrap_call(fun() -> websocket:close(Ws, StatusCode) end).

close_3(Ws, StatusCode, Reason) ->
    wrap_call(fun() -> websocket:close(Ws, StatusCode, Reason) end).

wrap_call(Fun) ->
    try
        wrap_ok(Fun())
    catch
        error:badarg ->
            {error, badarg};
        error:undef ->
            {error, not_supported};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{error, Reason} ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

wrap_value(Fun) ->
    try
        {ok, Fun()}
    catch
        error:badarg ->
            {error, badarg};
        error:undef ->
            {error, not_supported};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{error, Reason} ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

wrap_chardata(Fun) ->
    try
        {ok, chardata_to_binary(Fun())}
    catch
        error:badarg ->
            {error, badarg};
        error:undef ->
            {error, not_supported};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{error, Reason} ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

chardata_to_binary(Bin) when is_binary(Bin) ->
    Bin;
chardata_to_binary(Data) ->
    case unicode:characters_to_binary(Data) of
        Bin when is_binary(Bin) ->
            Bin;
        _ ->
            iolist_to_binary(Data)
    end.

wrap_ok(ok) ->
    {ok, nil};
wrap_ok(error) ->
    {error, failed};
wrap_ok({error, Reason}) ->
    wrap_reason(Reason).

wrap_reason(not_supported) ->
    {error, not_supported};
wrap_reason(badarg) ->
    {error, badarg};
wrap_reason(timeout) ->
    {error, timeout};
wrap_reason(not_owner) ->
    {error, not_owner};
wrap_reason(closed) ->
    {error, socket_closed};
wrap_reason(failed) ->
    {error, failed};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
