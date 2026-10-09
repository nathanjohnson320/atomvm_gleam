-module(atomvm_gleam_emscripten_ffi).
-export([
    run_script/1,
    run_script_opts/2,
    run_script_tracked/1,
    get_tracked/2,
    promise_resolve/1,
    promise_resolve_value/2,
    promise_reject/1,
    promise_reject_value/2,
    register_keypress/2,
    register_keypress_user_data/3,
    unregister_keypress/1,
    register_keydown/2,
    register_keydown_user_data/3,
    unregister_keydown/1,
    register_keyup/2,
    register_keyup_user_data/3,
    unregister_keyup/1,
    register_click/2,
    register_click_user_data/3,
    unregister_click/1,
    register_dblclick/2,
    register_dblclick_user_data/3,
    unregister_dblclick/1,
    register_mousedown/2,
    register_mousedown_user_data/3,
    unregister_mousedown/1,
    register_mouseup/2,
    register_mouseup_user_data/3,
    unregister_mouseup/1,
    register_mousemove/2,
    register_mousemove_user_data/3,
    unregister_mousemove/1,
    register_mouseenter/2,
    register_mouseenter_user_data/3,
    unregister_mouseenter/1,
    register_mouseleave/2,
    register_mouseleave_user_data/3,
    unregister_mouseleave/1,
    register_mouseover/2,
    register_mouseover_user_data/3,
    unregister_mouseover/1,
    register_mouseout/2,
    register_mouseout_user_data/3,
    unregister_mouseout/1,
    register_wheel/2,
    register_wheel_user_data/3,
    unregister_wheel/1,
    register_resize/2,
    register_resize_user_data/3,
    unregister_resize/1,
    register_scroll/2,
    register_scroll_user_data/3,
    unregister_scroll/1,
    register_blur/2,
    register_blur_user_data/3,
    unregister_blur/1,
    register_focus/2,
    register_focus_user_data/3,
    unregister_focus/1,
    register_focusin/2,
    register_focusin_user_data/3,
    unregister_focusin/1,
    register_focusout/2,
    register_focusout_user_data/3,
    unregister_focusout/1,
    register_touchstart/2,
    register_touchstart_user_data/3,
    unregister_touchstart/1,
    register_touchend/2,
    register_touchend_user_data/3,
    unregister_touchend/1,
    register_touchmove/2,
    register_touchmove_user_data/3,
    unregister_touchmove/1,
    register_touchcancel/2,
    register_touchcancel_user_data/3,
    unregister_touchcancel/1,
    map_raised/1
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

%% --- HTML5 register / unregister -------------------------------------------

register_keypress(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_keypress_callback(map_target(Target), map_register_options(Options))
    end).

register_keypress_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_keypress_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_keypress(Arg) ->
    wrap_call(fun() -> emscripten:unregister_keypress_callback(map_unregister(Arg)) end).

register_keydown(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_keydown_callback(map_target(Target), map_register_options(Options))
    end).

register_keydown_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_keydown_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_keydown(Arg) ->
    wrap_call(fun() -> emscripten:unregister_keydown_callback(map_unregister(Arg)) end).

register_keyup(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_keyup_callback(map_target(Target), map_register_options(Options))
    end).

register_keyup_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_keyup_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_keyup(Arg) ->
    wrap_call(fun() -> emscripten:unregister_keyup_callback(map_unregister(Arg)) end).

register_click(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_click_callback(map_target(Target), map_register_options(Options))
    end).

register_click_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_click_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_click(Arg) ->
    wrap_call(fun() -> emscripten:unregister_click_callback(map_unregister(Arg)) end).

register_dblclick(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_dblclick_callback(map_target(Target), map_register_options(Options))
    end).

register_dblclick_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_dblclick_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_dblclick(Arg) ->
    wrap_call(fun() -> emscripten:unregister_dblclick_callback(map_unregister(Arg)) end).

register_mousedown(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_mousedown_callback(map_target(Target), map_register_options(Options))
    end).

register_mousedown_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_mousedown_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_mousedown(Arg) ->
    wrap_call(fun() -> emscripten:unregister_mousedown_callback(map_unregister(Arg)) end).

register_mouseup(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_mouseup_callback(map_target(Target), map_register_options(Options))
    end).

register_mouseup_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_mouseup_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_mouseup(Arg) ->
    wrap_call(fun() -> emscripten:unregister_mouseup_callback(map_unregister(Arg)) end).

register_mousemove(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_mousemove_callback(map_target(Target), map_register_options(Options))
    end).

register_mousemove_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_mousemove_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_mousemove(Arg) ->
    wrap_call(fun() -> emscripten:unregister_mousemove_callback(map_unregister(Arg)) end).

register_mouseenter(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_mouseenter_callback(map_target(Target), map_register_options(Options))
    end).

register_mouseenter_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_mouseenter_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_mouseenter(Arg) ->
    wrap_call(fun() -> emscripten:unregister_mouseenter_callback(map_unregister(Arg)) end).

register_mouseleave(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_mouseleave_callback(map_target(Target), map_register_options(Options))
    end).

register_mouseleave_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_mouseleave_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_mouseleave(Arg) ->
    wrap_call(fun() -> emscripten:unregister_mouseleave_callback(map_unregister(Arg)) end).

register_mouseover(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_mouseover_callback(map_target(Target), map_register_options(Options))
    end).

register_mouseover_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_mouseover_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_mouseover(Arg) ->
    wrap_call(fun() -> emscripten:unregister_mouseover_callback(map_unregister(Arg)) end).

register_mouseout(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_mouseout_callback(map_target(Target), map_register_options(Options))
    end).

register_mouseout_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_mouseout_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_mouseout(Arg) ->
    wrap_call(fun() -> emscripten:unregister_mouseout_callback(map_unregister(Arg)) end).

register_wheel(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_wheel_callback(map_target(Target), map_register_options(Options))
    end).

register_wheel_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_wheel_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_wheel(Arg) ->
    wrap_call(fun() -> emscripten:unregister_wheel_callback(map_unregister(Arg)) end).

register_resize(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_resize_callback(map_target(Target), map_register_options(Options))
    end).

register_resize_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_resize_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_resize(Arg) ->
    wrap_call(fun() -> emscripten:unregister_resize_callback(map_unregister(Arg)) end).

register_scroll(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_scroll_callback(map_target(Target), map_register_options(Options))
    end).

register_scroll_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_scroll_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_scroll(Arg) ->
    wrap_call(fun() -> emscripten:unregister_scroll_callback(map_unregister(Arg)) end).

register_blur(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_blur_callback(map_target(Target), map_register_options(Options))
    end).

register_blur_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_blur_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_blur(Arg) ->
    wrap_call(fun() -> emscripten:unregister_blur_callback(map_unregister(Arg)) end).

register_focus(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_focus_callback(map_target(Target), map_register_options(Options))
    end).

register_focus_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_focus_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_focus(Arg) ->
    wrap_call(fun() -> emscripten:unregister_focus_callback(map_unregister(Arg)) end).

register_focusin(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_focusin_callback(map_target(Target), map_register_options(Options))
    end).

register_focusin_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_focusin_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_focusin(Arg) ->
    wrap_call(fun() -> emscripten:unregister_focusin_callback(map_unregister(Arg)) end).

register_focusout(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_focusout_callback(map_target(Target), map_register_options(Options))
    end).

register_focusout_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_focusout_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_focusout(Arg) ->
    wrap_call(fun() -> emscripten:unregister_focusout_callback(map_unregister(Arg)) end).

register_touchstart(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_touchstart_callback(map_target(Target), map_register_options(Options))
    end).

register_touchstart_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_touchstart_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_touchstart(Arg) ->
    wrap_call(fun() -> emscripten:unregister_touchstart_callback(map_unregister(Arg)) end).

register_touchend(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_touchend_callback(map_target(Target), map_register_options(Options))
    end).

register_touchend_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_touchend_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_touchend(Arg) ->
    wrap_call(fun() -> emscripten:unregister_touchend_callback(map_unregister(Arg)) end).

register_touchmove(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_touchmove_callback(map_target(Target), map_register_options(Options))
    end).

register_touchmove_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_touchmove_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_touchmove(Arg) ->
    wrap_call(fun() -> emscripten:unregister_touchmove_callback(map_unregister(Arg)) end).

register_touchcancel(Target, Options) ->
    wrap_register(fun() ->
        emscripten:register_touchcancel_callback(map_target(Target), map_register_options(Options))
    end).

register_touchcancel_user_data(Target, Options, UserData) ->
    wrap_register(fun() ->
        emscripten:register_touchcancel_callback(
            map_target(Target), map_register_options(Options), UserData
        )
    end).

unregister_touchcancel(Arg) ->
    wrap_call(fun() -> emscripten:unregister_touchcancel_callback(map_unregister(Arg)) end).

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

%% Gleam `Window` / `Document` / `Screen` / `CssSelector(S)` → html5_target().
map_target(window) ->
    window;
map_target(document) ->
    document;
map_target(screen) ->
    screen;
map_target({css_selector, Sel}) ->
    Sel.

%% Gleam `UseCapture` / `PreventDefault` tuples match Erlang register_option().
map_register_options(Options) ->
    Options.

%% Gleam `Handle(H)` / `Target(T)` → listener_handle() | html5_target().
map_unregister({handle, H}) ->
    H;
map_unregister({target, T}) ->
    map_target(T).

%% `{ok, Handle}` | `{ok, Handle, deferred}` | `{error, Reason}` → RegisterOk.
map_raised(Reason) when is_atom(Reason) ->
    wrap_call(fun() -> error(Reason) end).

wrap_register(Fun) ->
    try
        case Fun() of
            {ok, Handle, deferred} ->
                {ok, {deferred, Handle}};
            {ok, Handle} ->
                {ok, {registered, Handle}};
            {error, ErrReason} ->
                wrap_reason(ErrReason);
            error ->
                {error, failed}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:undef ->
            {error, not_supported};
        error:undefined ->
            {error, failed};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        error:{error, Thrown} ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

wrap_call(Fun) ->
    try
        wrap_ok(Fun())
    catch
        error:badarg ->
            {error, badarg};
        error:undef ->
            {error, not_supported};
        error:undefined ->
            {error, failed};
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
            {error, failed};
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
wrap_reason(timed_out) ->
    {error, timed_out};
wrap_reason(failed) ->
    {error, failed};
wrap_reason(invalid_target) ->
    {error, invalid_target};
wrap_reason(unknown_target) ->
    {error, unknown_target};
wrap_reason(failed_not_deferred) ->
    {error, failed_not_deferred};
wrap_reason(no_data) ->
    {error, no_data};
wrap_reason(Reason) when is_integer(Reason) ->
    {error, {code, Reason}};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
