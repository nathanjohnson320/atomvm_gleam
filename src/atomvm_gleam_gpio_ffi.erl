-module(atomvm_gleam_gpio_ffi).
-export([
    open/0,
    start/0,
    close/1,
    stop/0,
    set_direction/3,
    set_level/3,
    read/2,
    set_int/3,
    set_int_to/4,
    remove_int/2,
    attach_interrupt/2,
    detach_interrupt/1,
    init/1,
    deinit/1,
    set_function/2,
    set_pin_mode/2,
    set_pin_pull/2,
    digital_read/1,
    digital_write/2,
    hold_en/1,
    hold_dis/1,
    deep_sleep_hold_en/0,
    deep_sleep_hold_dis/0,
    wakeup_enable/2,
    set_sysfs_base/1
]).

open() ->
    try_gpio(fun() -> gpio:open() end).

start() ->
    try_gpio(fun() -> gpio:start() end).

close(Gpio) ->
    try_ok(fun() -> gpio:close(Gpio) end).

stop() ->
    try_ok(fun() -> gpio:stop() end).

set_direction(Gpio, Pin, Direction) ->
    try_ok(fun() -> gpio:set_direction(Gpio, pin_term(Pin), Direction) end).

set_level(Gpio, Pin, Level) ->
    try_ok(fun() -> gpio:set_level(Gpio, pin_term(Pin), level_atom(Level)) end).

read(Gpio, Pin) ->
    try_level(fun() -> gpio:read(Gpio, pin_term(Pin)) end).

set_int(Gpio, Pin, Trigger) ->
    try_ok(fun() -> gpio:set_int(Gpio, pin_term(Pin), Trigger) end).

set_int_to(Gpio, Pin, Trigger, Pid) ->
    try_ok(fun() -> gpio:set_int(Gpio, pin_term(Pin), Trigger, Pid) end).

remove_int(Gpio, Pin) ->
    try_ok(fun() -> gpio:remove_int(Gpio, pin_term(Pin)) end).

attach_interrupt(Pin, Trigger) ->
    try_ok(fun() -> gpio:attach_interrupt(pin_term(Pin), Trigger) end).

detach_interrupt(Pin) ->
    try_ok(fun() -> gpio:detach_interrupt(pin_term(Pin)) end).

init(Pin) ->
    try_ok(fun() -> gpio:init(pin_term(Pin)) end).

deinit(Pin) ->
    try_ok(fun() -> gpio:deinit(pin_term(Pin)) end).

set_function(Pin, Function) ->
    try_ok(fun() -> gpio:set_function(Pin, Function) end).

set_pin_mode(Pin, Direction) ->
    try_ok(fun() -> gpio:set_pin_mode(pin_term(Pin), Direction) end).

set_pin_pull(Pin, Pull) ->
    try_ok(fun() -> gpio:set_pin_pull(pin_term(Pin), Pull) end).

digital_read(Pin) ->
    try_level(fun() -> gpio:digital_read(pin_term(Pin)) end).

digital_write(Pin, Level) ->
    try_ok(fun() -> gpio:digital_write(pin_term(Pin), level_atom(Level)) end).

hold_en(Pin) ->
    try_ok(fun() -> gpio:hold_en(pin_term(Pin)) end).

hold_dis(Pin) ->
    try_ok(fun() -> gpio:hold_dis(pin_term(Pin)) end).

deep_sleep_hold_en() ->
    try_ok(fun() -> gpio:deep_sleep_hold_en() end).

deep_sleep_hold_dis() ->
    try_ok(fun() -> gpio:deep_sleep_hold_dis() end).

wakeup_enable(Pin, Level) ->
    try_ok(fun() -> gpio:wakeup_enable(pin_term(Pin), level_atom(Level)) end).

%% Generic UNIX / Linux only (`avm_unix` gpio). Gleam String → Erlang string list.
set_sysfs_base(Dir) ->
    try_ok(fun() ->
        gpio:set_sysfs_base(unicode:characters_to_list(Dir))
    end).

%% Gleam `PinNum(N)` / `WlPin(N)` → AtomVM pin term (`N` or `{wl, N}`).
pin_term({pin_num, N}) when is_integer(N) ->
    N;
pin_term({wl_pin, N}) when is_integer(N) ->
    {wl, N}.

level_atom(pin_high) ->
    high;
level_atom(pin_low) ->
    low.

try_gpio(Fun) ->
    try
        wrap_gpio(Fun())
    catch
        error:undef ->
            {error, not_supported};
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{error, Reason} ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

try_ok(Fun) ->
    try
        wrap_ok(Fun())
    catch
        error:undef ->
            {error, not_supported};
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{error, Reason} ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

try_level(Fun) ->
    try
        wrap_level(Fun())
    catch
        error:undef ->
            {error, not_supported};
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{error, Reason} ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

wrap_gpio(error) ->
    {error, failed};
wrap_gpio({error, Reason}) ->
    wrap_reason(Reason);
wrap_gpio(Gpio) ->
    {ok, Gpio}.

wrap_ok(ok) ->
    {ok, nil};
wrap_ok(error) ->
    {error, failed};
wrap_ok({error, Reason}) ->
    wrap_reason(Reason).

wrap_level(high) ->
    {ok, pin_high};
wrap_level(low) ->
    {ok, pin_low};
wrap_level(error) ->
    {error, failed};
wrap_level({error, Reason}) ->
    wrap_reason(Reason).

%% Map AtomVM `{error, Reason}` atoms onto Gleam `Error` constructors.
%% Known atoms pass through as zero-arity variants; anything else is `Other`.
wrap_reason(not_supported) ->
    {error, not_supported};
wrap_reason(badarg) ->
    {error, badarg};
wrap_reason(timeout) ->
    {error, timeout};
wrap_reason(failed) ->
    {error, failed};
wrap_reason(undef) ->
    {error, not_supported};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
