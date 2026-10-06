-module(atomvm_gleam_emscripten_ffi).
-export([
    run_script/1,
    run_script_opts/2,
    run_script_tracked/1,
    get_tracked/2,
    promise_resolve/1,
    promise_resolve_value/2,
    promise_reject/1,
    promise_reject_value/2
]).

run_script(Script) ->
    wrap_call(fun() -> emscripten:run_script(Script) end).

run_script_opts(Script, Options) ->
    wrap_call(fun() -> emscripten:run_script(Script, map_options(Options)) end).

run_script_tracked(Script) ->
    wrap_call_value(fun() -> emscripten:run_script_tracked(Script) end).

get_tracked(Objects, Field) ->
    wrap_call_value(fun() ->
        case Field of
            tracked_key ->
                {ok, {keys, emscripten:get_tracked(Objects, key)}};
            tracked_value ->
                Raw = emscripten:get_tracked(Objects, value),
                {ok, {values, [map_tracked_value(R) || R <- Raw]}}
        end
    end).

promise_resolve(Promise) ->
    wrap_call(fun() -> emscripten:promise_resolve(Promise) end).

promise_resolve_value(Promise, Value) ->
    wrap_call(fun() -> emscripten:promise_resolve(Promise, map_promise_value(Value)) end).

promise_reject(Promise) ->
    wrap_call(fun() -> emscripten:promise_reject(Promise) end).

promise_reject_value(Promise, Value) ->
    wrap_call(fun() -> emscripten:promise_reject(Promise, map_promise_value(Value)) end).

%% Gleam `MainThread` / `Async` → Erlang `main_thread` / `async` (identity).
map_options(Options) ->
    Options.

%% Gleam `IntValue(N)` / `StringValue(S)` → integer | iodata.
map_promise_value({int_value, N}) when is_integer(N) ->
    N;
map_promise_value({string_value, S}) ->
    S.

%% Upstream `{ok, Bin}` | `{error, badkey}` | `{error, badvalue}` → Gleam Result.
map_tracked_value({ok, Bin}) when is_binary(Bin) ->
    {ok, Bin};
map_tracked_value({error, badkey}) ->
    {error, bad_key};
map_tracked_value({error, badvalue}) ->
    {error, bad_value}.

wrap_call(Fun) ->
    try
        wrap_ok(Fun())
    catch
        error:badarg ->
            {error, badarg};
        error:undef ->
            {error, not_supported};
        error:undefined ->
            {error, not_supported};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{error, Reason} ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

wrap_call_value(Fun) ->
    try
        case Fun() of
            {ok, Value} ->
                {ok, Value};
            {error, ErrReason} ->
                wrap_reason(ErrReason);
            error ->
                {error, failed};
            Value ->
                {ok, Value}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:undef ->
            {error, not_supported};
        error:undefined ->
            {error, not_supported};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        error:{error, Thrown} ->
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
