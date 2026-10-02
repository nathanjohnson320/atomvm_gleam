-module(atomvm_gleam_ssl_ffi).
-export([start/0, stop/0]).

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
