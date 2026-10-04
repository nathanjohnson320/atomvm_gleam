-module(atomvm_gleam_console_ffi).
-export([start/0, puts/1, print/1, flush/0, print_err/1]).

start() ->
    try
        _Port = console:start(),
        {ok, nil}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{error, Reason} ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

puts(Text) ->
    wrap_call(fun() -> console:puts(Text) end).

print(Text) ->
    wrap_call(fun() -> console:print(Text) end).

flush() ->
    wrap_call(fun() -> console:flush() end).

print_err(Text) ->
    wrap_call(fun() -> console:print_err(Text) end).

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
