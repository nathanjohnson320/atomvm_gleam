-module(atomvm_gleam_http_ffi).
-export([connect/5, request/5, stream/2, stream_request_body/3, recv/2, close/1]).

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
    BodyArg = body_arg(Body),
    case ahttp_client:request(Conn, Method, Path, Hdrs, BodyArg) of
        {ok, NewConn, Ref} ->
            {ok, {NewConn, Ref}};
        {error, Reason} ->
            wrap_backend_error(Reason);
        error ->
            {error, failed}
    end.

stream(Conn, Msg) ->
    case ahttp_client:stream(Conn, Msg) of
        {ok, NewConn, closed} ->
            {ok, {closed, NewConn}};
        {ok, NewConn, Responses} when is_list(Responses) ->
            {ok, {responses, NewConn, [map_response(R) || R <- Responses]}};
        unknown ->
            {ok, unknown};
        {error, Reason} ->
            wrap_backend_error(Reason);
        error ->
            {error, failed}
    end.

stream_request_body(Conn, Ref, Chunk) ->
    case ahttp_client:stream_request_body(Conn, Ref, Chunk) of
        {ok, NewConn, NewRef} ->
            {ok, {NewConn, NewRef}};
        ok ->
            {ok, {Conn, Ref}};
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

body_arg(empty) ->
    undefined;
body_arg({bytes, Bytes}) ->
    Bytes;
body_arg(stream) ->
    stream;
%% Legacy Option(BitArray) shapes, if any Erlang caller still passes them.
body_arg(none) ->
    undefined;
body_arg({some, Bytes}) ->
    Bytes.

map_response({status, Ref, Code}) ->
    {status, Ref, Code};
map_response({header, Ref, {Name, Value}}) ->
    {header, Ref, iolist_to_binary(Name), iolist_to_binary(Value)};
map_response({header_continuation, Ref, {Name, Value}}) ->
    {header_continuation, Ref, iolist_to_binary(Name), iolist_to_binary(Value)};
map_response({trailer_header, Ref, {Name, Value}}) ->
    {trailer_header, Ref, iolist_to_binary(Name), iolist_to_binary(Value)};
map_response({data, Ref, Data}) ->
    {data, Ref, iolist_to_binary(Data)};
map_response({done, Ref}) ->
    {done, Ref}.

%% `{Backend, Reason}` covers `{gen_tcp | ssl | parser, …}` including nested
%% parser tuples such as `{line_too_long, Prefix}` / `incomplete_response`.
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
