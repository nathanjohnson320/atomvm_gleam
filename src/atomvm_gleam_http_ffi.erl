-module(atomvm_gleam_http_ffi).
-export([connect/5, request/5, recv/2, close/1]).

connect(Protocol, Host, Port, Active, Verify) ->
    Opts = [{active, Active}] ++ verify_opt(Verify),
    case ahttp_client:connect(protocol(Protocol), Host, Port, Opts) of
        {ok, Conn} ->
            {ok, Conn};
        {error, Reason} ->
            wrap_backend_error(Reason);
        error ->
            {error, failed}
    end.

request(Conn, Method, Path, Headers, Body) ->
    Hdrs = [{Name, Value} || {Name, Value} <- Headers],
    BodyArg =
        case Body of
            none ->
                undefined;
            {some, Bytes} ->
                Bytes
        end,
    case ahttp_client:request(Conn, Method, Path, Hdrs, BodyArg) of
        {ok, NewConn, Ref} ->
            {ok, {NewConn, Ref}};
        {error, Reason} ->
            wrap_backend_error(Reason);
        error ->
            {error, failed}
    end.

recv(Conn, Len) ->
    case ahttp_client:recv(Conn, Len) of
        {ok, NewConn, Responses} ->
            {ok, {NewConn, [map_response(R) || R <- Responses]}};
        {error, Reason} ->
            wrap_backend_error(Reason);
        error ->
            {error, failed}
    end.

close(Conn) ->
    case ahttp_client:close(Conn) of
        ok ->
            {ok, nil};
        {error, Reason} ->
            wrap_backend_error(Reason);
        error ->
            {error, failed}
    end.

protocol(http) ->
    http;
protocol(https) ->
    https.

verify_opt(none) ->
    [];
verify_opt({some, verify_none}) ->
    [{verify, verify_none}];
verify_opt({some, verify_peer}) ->
    [{verify, verify_peer}].

map_response({status, Ref, Code}) ->
    {status, Ref, Code};
map_response({header, Ref, {Name, Value}}) ->
    {header, Ref, iolist_to_binary(Name), iolist_to_binary(Value)};
map_response({header_continuation, Ref, {Name, Value}}) ->
    {header_continuation, Ref, iolist_to_binary(Name), iolist_to_binary(Value)};
map_response({data, Ref, Data}) ->
    {data, Ref, iolist_to_binary(Data)};
map_response({done, Ref}) ->
    {done, Ref}.

wrap_backend_error({_Backend, Reason}) ->
    wrap_reason(Reason);
wrap_backend_error(Reason) ->
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
