-module(atomvm_gleam_http_server_ffi).
-export([start_server/2, reply/3, reply/4, parse_query_string/1]).

start_server(Port, Routes) ->
    Router = [to_route(R) || R <- Routes],
    try
        case http_server:start_server(Port, Router) of
            Pid when is_pid(Pid) ->
                {ok, Pid};
            {error, Reason} ->
                wrap_reason(Reason);
            error ->
                {error, failed};
            _Other ->
                {error, failed}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:CatchReason ->
            wrap_reason(CatchReason)
    end.

reply(StatusCode, Body, Conn) ->
    wrap_conn(http_server:reply(StatusCode, Body, Conn)).

reply(StatusCode, Body, Headers, Conn) ->
    wrap_conn(http_server:reply(StatusCode, Body, Headers, Conn)).

parse_query_string(Query) when is_binary(Query) ->
    try
        Pairs = http_server:parse_query_string(unicode:characters_to_list(Query)),
        {ok, [{to_bin(K), to_bin(V)} || {K, V} <- Pairs]}
    catch
        error:badarg ->
            {error, badarg};
        error:CatchReason ->
            wrap_reason(CatchReason)
    end;
parse_query_string(Query) when is_list(Query) ->
    parse_query_string(unicode:characters_to_binary(Query));
parse_query_string(_Query) ->
    {error, badarg}.

%% Gleam `Route(path, module)` → `{route, PathBin, ModuleAtom}`.
%% Upstream expects `{PathCharlist, Module, Opts}`.
to_route({route, Path, Module}) when is_atom(Module) ->
    {to_charlist(Path), Module, []};
to_route({Path, Module, Opts}) when is_atom(Module) ->
    {to_charlist(Path), Module, Opts}.

to_charlist(Path) when is_list(Path) ->
    Path;
to_charlist(Path) when is_binary(Path) ->
    unicode:characters_to_list(Path).

to_bin(Value) when is_binary(Value) ->
    Value;
to_bin(Value) when is_list(Value) ->
    unicode:characters_to_binary(Value);
to_bin(Value) when is_atom(Value) ->
    atom_to_binary(Value, utf8);
to_bin(Value) ->
    iolist_to_binary(io_lib:format("~p", [Value])).

wrap_conn({ok, Conn}) ->
    {ok, Conn};
wrap_conn({error, Reason}) ->
    wrap_reason(Reason);
wrap_conn(error) ->
    {error, failed}.

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
