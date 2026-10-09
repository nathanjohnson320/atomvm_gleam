%% Test router module for AtomVM `http_server` integration tests.
%%
%% Packed into tests.avm and referenced by atom name from Gleam
%% (`http_server.route(..., atom.create("avm_http_test_handler"))`).
%% Calls through `atomvm_gleam_http_server_ffi` so reply / reply_with_headers
%% FFI mapping is exercised end-to-end.
-module(avm_http_test_handler).
-export([handle_req/3]).

handle_req(_Method, Path, Conn) ->
    try
        dispatch(Path, Conn)
    catch
        Class:Reason:Stack ->
            erlang:display({avm_http_test_handler_crash, Class, Reason, Stack}),
            http_server:reply(500, <<"handler-crash">>, Conn)
    end.

dispatch([], Conn) ->
    Body = <<"hello-gleam">>,
    %% reply/4 (Gleam FFI) without closing — Content-Length lets the client
    %% finish parsing; immediate close races passive recv on generic_unix.
    atomvm_gleam_http_server_ffi:reply(200, Body, default_headers(Body), Conn);
dispatch(["headers"], Conn) ->
    Body = <<"with-headers">>,
    Hdrs = [
        <<"Content-Type: text/plain\r\n">>,
        content_length(Body),
        <<"X-Test: ok\r\n">>,
        <<"Connection: close\r\n">>
    ],
    atomvm_gleam_http_server_ffi:reply(200, Body, Hdrs, Conn);
dispatch(["reply3"], Conn) ->
    %% Gleam FFI reply/3 — sends default headers and closes the socket.
    atomvm_gleam_http_server_ffi:reply(200, <<"via-reply3">>, Conn);
dispatch(_Path, Conn) ->
    atomvm_gleam_http_server_ffi:reply(404, <<"missing">>, Conn).

default_headers(Body) ->
    [
        <<"Content-Type: text/html\r\n">>,
        content_length(Body),
        <<"Connection: close\r\n">>
    ].

content_length(Body) ->
    Len = integer_to_binary(byte_size(Body)),
    <<"Content-Length: ", Len/binary, "\r\n">>.
