-module(atomvm_gleam_ssl_ffi).
-export([start/0, stop/0, connect/4, send/2, recv/2, close/1]).

start() ->
    case ssl:start() of
        ok ->
            nil;
        {ok, _} ->
            nil;
        _ ->
            nil
    end.

stop() ->
    case ssl:stop() of
        ok ->
            nil;
        _ ->
            nil
    end.

connect(Host, Port, Verify, Sni) ->
    HostArg = unicode:characters_to_list(Host),
    Opts = [{active, false}, binary] ++ verify_opt(Verify) ++ sni_opt(Sni),
    case ssl:connect(HostArg, Port, Opts) of
        {ok, Sock} ->
            {ok, Sock};
        {error, Reason} ->
            wrap_reason(Reason);
        error ->
            {error, failed}
    end.

send(Sock, Data) ->
    wrap_ok(ssl:send(Sock, Data)).

recv(Sock, Length) ->
    case ssl:recv(Sock, Length) of
        {ok, Data} when is_binary(Data) ->
            {ok, Data};
        {ok, Data} ->
            {ok, iolist_to_binary(Data)};
        {error, Reason} ->
            wrap_reason(Reason);
        error ->
            {error, failed}
    end.

close(Sock) ->
    wrap_ok(ssl:close(Sock)).

verify_opt(none) ->
    [];
verify_opt({some, verify_none}) ->
    [{verify, verify_none}].

sni_opt(none) ->
    [];
sni_opt({some, disabled}) ->
    [{server_name_indication, disabled}];
sni_opt({some, {hostname, Name}}) ->
    [{server_name_indication, unicode:characters_to_list(Name)}].

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
wrap_reason(closed) ->
    {error, closed};
wrap_reason(nxdomain) ->
    {error, nxdomain};
wrap_reason(failed) ->
    {error, failed};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
