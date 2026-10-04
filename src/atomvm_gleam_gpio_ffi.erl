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
    wakeup_enable/2
]).

open() ->
    wrap_gpio(gpio:open()).

start() ->
    wrap_gpio(gpio:start()).

close(Gpio) ->
    wrap_ok(gpio:close(Gpio)).

stop() ->
    wrap_ok(gpio:stop()).

set_direction(Gpio, Pin, Direction) ->
    wrap_ok(gpio:set_direction(Gpio, pin_term(Pin), Direction)).

set_level(Gpio, Pin, Level) ->
    wrap_ok(gpio:set_level(Gpio, pin_term(Pin), level_atom(Level))).

read(Gpio, Pin) ->
    wrap_level(gpio:read(Gpio, pin_term(Pin))).

set_int(Gpio, Pin, Trigger) ->
    wrap_ok(gpio:set_int(Gpio, pin_term(Pin), Trigger)).

set_int_to(Gpio, Pin, Trigger, Pid) ->
    wrap_ok(gpio:set_int(Gpio, pin_term(Pin), Trigger, Pid)).

remove_int(Gpio, Pin) ->
    wrap_ok(gpio:remove_int(Gpio, pin_term(Pin))).

attach_interrupt(Pin, Trigger) ->
    wrap_ok(gpio:attach_interrupt(pin_term(Pin), Trigger)).

detach_interrupt(Pin) ->
    wrap_ok(gpio:detach_interrupt(pin_term(Pin))).

init(Pin) ->
    wrap_ok(gpio:init(pin_term(Pin))).

deinit(Pin) ->
    wrap_ok(gpio:deinit(pin_term(Pin))).

set_function(Pin, Function) ->
    wrap_ok(gpio:set_function(Pin, Function)).

set_pin_mode(Pin, Direction) ->
    wrap_ok(gpio:set_pin_mode(pin_term(Pin), Direction)).

set_pin_pull(Pin, Pull) ->
    wrap_ok(gpio:set_pin_pull(pin_term(Pin), Pull)).

digital_read(Pin) ->
    wrap_level(gpio:digital_read(pin_term(Pin))).

digital_write(Pin, Level) ->
    wrap_ok(gpio:digital_write(pin_term(Pin), level_atom(Level))).

hold_en(Pin) ->
    wrap_ok(gpio:hold_en(pin_term(Pin))).

hold_dis(Pin) ->
    wrap_ok(gpio:hold_dis(pin_term(Pin))).

deep_sleep_hold_en() ->
    wrap_ok(gpio:deep_sleep_hold_en()).

deep_sleep_hold_dis() ->
    wrap_ok(gpio:deep_sleep_hold_dis()).

wakeup_enable(Pin, Level) ->
    wrap_ok(gpio:wakeup_enable(pin_term(Pin), level_atom(Level))).

%% Gleam `PinNum(N)` / `WlPin(N)` → AtomVM pin term (`N` or `{wl, N}`).
pin_term({pin_num, N}) when is_integer(N) ->
    N;
pin_term({wl_pin, N}) when is_integer(N) ->
    {wl, N}.

level_atom(pin_high) ->
    high;
level_atom(pin_low) ->
    low.

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
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
