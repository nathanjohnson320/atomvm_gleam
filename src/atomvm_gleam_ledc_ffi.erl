-module(atomvm_gleam_ledc_ffi).
-export([
    timer_config/4,
    channel_config/6,
    set_duty/3,
    update_duty/2,
    fade_func_install/1,
    fade_func_uninstall/0,
    set_fade_with_time/4,
    set_fade_with_step/5,
    set_fade_time_and_start/5,
    set_fade_step_and_start/6,
    fade_start/3,
    fade_stop/2,
    set_duty_and_update/4,
    get_duty/2,
    get_freq/2,
    set_freq/3,
    stop/3
]).

timer_config(DutyResolution, FreqHz, SpeedMode, TimerNum) ->
    wrap_ok(ledc:timer_config([
        {duty_resolution, DutyResolution},
        {freq_hz, FreqHz},
        {speed_mode, speed_mode(SpeedMode)},
        {timer_num, TimerNum}
    ])).

channel_config(Channel, Duty, GpioNum, SpeedMode, Hpoint, TimerSel) ->
    wrap_ok(ledc:channel_config([
        {channel, Channel},
        {duty, Duty},
        {gpio_num, GpioNum},
        {speed_mode, speed_mode(SpeedMode)},
        {hpoint, Hpoint},
        {timer_sel, TimerSel}
    ])).

set_duty(SpeedMode, Channel, Duty) ->
    wrap_ok(ledc:set_duty(speed_mode(SpeedMode), Channel, Duty)).

update_duty(SpeedMode, Channel) ->
    wrap_ok(ledc:update_duty(speed_mode(SpeedMode), Channel)).

fade_func_install(Flags) ->
    try_ok(fun() -> ledc:fade_func_install(Flags) end).

fade_func_uninstall() ->
    try_ok(fun() -> ledc:fade_func_uninstall() end).

set_fade_with_time(SpeedMode, Channel, TargetDuty, MaxFadeTimeMs) ->
    try_ok(fun() ->
        ledc:set_fade_with_time(
            speed_mode(SpeedMode), Channel, TargetDuty, MaxFadeTimeMs
        )
    end).

set_fade_with_step(SpeedMode, Channel, TargetDuty, Scale, CycleNum) ->
    try_ok(fun() ->
        ledc:set_fade_with_step(
            speed_mode(SpeedMode), Channel, TargetDuty, Scale, CycleNum
        )
    end).

set_fade_time_and_start(SpeedMode, Channel, TargetDuty, MaxFadeTimeMs, FadeMode) ->
    try_ok(fun() ->
        ledc:set_fade_time_and_start(
            speed_mode(SpeedMode),
            Channel,
            TargetDuty,
            MaxFadeTimeMs,
            FadeMode
        )
    end).

set_fade_step_and_start(
    SpeedMode, Channel, TargetDuty, Scale, CycleNum, FadeMode
) ->
    try_ok(fun() ->
        ledc:set_fade_step_and_start(
            speed_mode(SpeedMode),
            Channel,
            TargetDuty,
            Scale,
            CycleNum,
            FadeMode
        )
    end).

fade_start(SpeedMode, Channel, FadeMode) ->
    try_ok(fun() ->
        ledc:fade_start(speed_mode(SpeedMode), Channel, FadeMode)
    end).

fade_stop(SpeedMode, Channel) ->
    try_ok(fun() -> ledc:fade_stop(speed_mode(SpeedMode), Channel) end).

set_duty_and_update(SpeedMode, Channel, Duty, HPoint) ->
    try_ok(fun() ->
        ledc:set_duty_and_update(
            speed_mode(SpeedMode), Channel, Duty, HPoint
        )
    end).

get_duty(SpeedMode, Channel) ->
    try_int(fun() -> ledc:get_duty(speed_mode(SpeedMode), Channel) end).

get_freq(SpeedMode, TimerNum) ->
    try_int(fun() -> ledc:get_freq(speed_mode(SpeedMode), TimerNum) end).

set_freq(SpeedMode, TimerNum, FreqHz) ->
    try_ok(fun() ->
        ledc:set_freq(speed_mode(SpeedMode), TimerNum, FreqHz)
    end).

stop(SpeedMode, Channel, IdleLevel) ->
    try_ok(fun() ->
        ledc:stop(speed_mode(SpeedMode), Channel, IdleLevel)
    end).

speed_mode(high_speed) ->
    0;
speed_mode(low_speed) ->
    1.

try_ok(Fun) ->
    try Fun() of
        Result -> wrap_ok(Result)
    catch
        error:Reason -> wrap_thrown(Reason);
        throw:Reason -> wrap_thrown(Reason)
    end.

try_int(Fun) ->
    try Fun() of
        Result -> wrap_int(Result)
    catch
        error:Reason -> wrap_thrown(Reason);
        throw:Reason -> wrap_thrown(Reason)
    end.

wrap_thrown({error, Reason}) ->
    wrap_reason(Reason);
wrap_thrown(Reason) ->
    wrap_reason(Reason).

wrap_int(Value) when is_integer(Value) ->
    {ok, Value};
wrap_int(error) ->
    {error, failed};
wrap_int({error, Reason}) ->
    wrap_reason(Reason).

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
wrap_reason(Code) when is_integer(Code) ->
    {error, {code, Code}};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
