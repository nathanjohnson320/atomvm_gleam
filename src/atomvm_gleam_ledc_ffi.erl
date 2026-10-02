-module(atomvm_gleam_ledc_ffi).
-export([
    timer_config/4,
    channel_config/6,
    set_duty/3,
    update_duty/2
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

speed_mode(high_speed) ->
    0;
speed_mode(low_speed) ->
    1.

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
