-module(atomvm_gleam_websocket_ffi).
-export([open/5, send_text/2, send_binary/2, close/1]).

open(Url, Owner, Verify, NetworkTimeoutMs, DisableAutoReconnect) ->
    Config0 = #{url => Url},
    Config1 = put_opt(Config0, owner, Owner),
    Config2 = put_verify(Config1, Verify),
    Config3 = put_opt(Config2, network_timeout_ms, NetworkTimeoutMs),
    Config4 = put_opt(Config3, disable_auto_reconnect, DisableAutoReconnect),
    case websocket_client:open(Config4) of
        {ok, Port} ->
            {ok, Port};
        {error, Reason} ->
            wrap_reason(Reason);
        error ->
            {error, failed}
    end.

send_text(Port, Data) ->
    wrap_ok(websocket_client:send_text(Port, Data)).

send_binary(Port, Data) ->
    wrap_ok(websocket_client:send_binary(Port, Data)).

close(Port) ->
    wrap_ok(websocket_client:close(Port)).

put_opt(Map, _Key, none) ->
    Map;
put_opt(Map, Key, {some, Value}) ->
    Map#{Key => Value}.

put_verify(Map, none) ->
    Map;
put_verify(Map, {some, crt_bundle}) ->
    Map#{verify => crt_bundle};
put_verify(Map, {some, no_verify}) ->
    Map#{verify => none}.

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
wrap_reason(missing_url) ->
    {error, missing_url};
wrap_reason(not_connected) ->
    {error, not_connected};
wrap_reason(failed) ->
    {error, failed};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
