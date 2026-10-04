-module(atomvm_gleam_mdns_ffi).
-export([start_link/6, stop/1]).

start_link(Hostname, A, B, C, D, Ttl) ->
    Config0 = #{
        hostname => Hostname,
        interface => {A, B, C, D}
    },
    Config =
        case Ttl of
            none ->
                Config0;
            {some, Value} ->
                Config0#{ttl => Value}
        end,
    try
        case mdns:start_link(Config) of
            {ok, Pid} ->
                {ok, Pid};
            {error, Reason} ->
                wrap_reason(Reason);
            error ->
                {error, failed}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

stop(Server) ->
    try
        wrap_ok(mdns:stop(Server))
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
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
wrap_reason(failed) ->
    {error, failed};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
