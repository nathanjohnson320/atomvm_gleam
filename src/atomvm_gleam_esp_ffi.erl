-module(atomvm_gleam_esp_ffi).
-export([
    nvs_get_binary/2,
    nvs_fetch_binary/2,
    nvs_put_binary/3,
    nvs_set_binary/3,
    nvs_erase_key/2,
    nvs_erase_all/1,
    nvs_reformat/0,
    get_default_mac/0,
    get_mac/1,
    reset_reason/0,
    restart/0,
    freq_hz/0,
    timer_get_time/0,
    sleep_enable_gpio_wakeup/0,
    light_sleep/0,
    deep_sleep/0,
    deep_sleep_ms/1,
    sleep_get_wakeup_cause/0,
    sleep_enable_ext0_wakeup/2,
    sleep_enable_ext1_wakeup/2,
    sleep_enable_ext1_wakeup_io/2,
    sleep_disable_ext1_wakeup_io/1,
    deep_sleep_enable_gpio_wakeup/2,
    sleep_enable_ulp_wakeup/0,
    sleep_enable_timer_wakeup/1,
    partition_list/0,
    partition_read/3,
    partition_mmap/3,
    partition_write/3,
    partition_erase_range/2,
    partition_erase_range_size/3,
    rtc_slow_get_binary/0,
    rtc_slow_set_binary/1,
    mount/4,
    umount/1,
    task_wdt_init/3,
    task_wdt_reconfigure/3,
    task_wdt_deinit/0,
    task_wdt_add_user/1,
    task_wdt_reset_user/1,
    task_wdt_delete_user/1
]).

nvs_get_binary(Namespace, Key) ->
    try
        case esp:nvs_get_binary(name_atom(Namespace), name_atom(Key)) of
            undefined ->
                {ok, none};
            Value when is_binary(Value) ->
                {ok, {some, Value}}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

nvs_fetch_binary(Namespace, Key) ->
    try
        case esp:nvs_fetch_binary(name_atom(Namespace), name_atom(Key)) of
            {ok, Value} when is_binary(Value) ->
                {ok, Value};
            {error, Reason} ->
                wrap_reason(Reason)
        end
    catch
        error:badarg ->
            {error, badarg};
        error:CatchReason when is_atom(CatchReason) ->
            wrap_reason(CatchReason);
        _:_ ->
            {error, failed}
    end.

nvs_put_binary(Namespace, Key, Value) ->
    try
        ok = esp:nvs_put_binary(name_atom(Namespace), name_atom(Key), Value),
        {ok, nil}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

nvs_set_binary(Namespace, Key, Value) ->
    try
        ok = esp:nvs_set_binary(name_atom(Namespace), name_atom(Key), Value),
        {ok, nil}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

nvs_erase_key(Namespace, Key) ->
    try
        ok = esp:nvs_erase_key(name_atom(Namespace), name_atom(Key)),
        {ok, nil}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

nvs_erase_all(Namespace) ->
    try
        ok = esp:nvs_erase_all(name_atom(Namespace)),
        {ok, nil}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

nvs_reformat() ->
    try
        ok = esp:nvs_reformat(),
        {ok, nil}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

get_default_mac() ->
    case esp:get_default_mac() of
        {ok, Mac} ->
            {ok, Mac};
        {error, Reason} ->
            wrap_reason(Reason);
        error ->
            {error, failed}
    end.

get_mac(Interface) ->
    try
        Mac = esp:get_mac(Interface),
        {ok, Mac}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

reset_reason() ->
    case esp:reset_reason() of
        esp_rst_unknown ->
            esp_rst_unknown;
        esp_rst_poweron ->
            esp_rst_poweron;
        esp_rst_ext ->
            esp_rst_ext;
        esp_rst_sw ->
            esp_rst_sw;
        esp_rst_panic ->
            esp_rst_panic;
        esp_rst_int_wdt ->
            esp_rst_int_wdt;
        esp_rst_task_wdt ->
            esp_rst_task_wdt;
        esp_rst_wdt ->
            esp_rst_wdt;
        esp_rst_deepsleep ->
            esp_rst_deepsleep;
        esp_rst_brownout ->
            esp_rst_brownout;
        esp_rst_sdio ->
            esp_rst_sdio;
        esp_rst_usb ->
            esp_rst_usb;
        esp_rst_jtag ->
            esp_rst_jtag;
        esp_rst_efuse ->
            esp_rst_efuse;
        esp_rst_pwr_glitch ->
            esp_rst_pwr_glitch;
        esp_rst_cpu_lockup ->
            esp_rst_cpu_lockup;
        Reason when is_atom(Reason) ->
            {other_reason, atom_to_binary(Reason, utf8)};
        Reason ->
            {other_reason, iolist_to_binary(io_lib:format("~p", [Reason]))}
    end.

restart() ->
    esp:restart(),
    nil.

freq_hz() ->
    try
        {ok, esp:freq_hz()}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

timer_get_time() ->
    try
        {ok, esp:timer_get_time()}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

sleep_enable_gpio_wakeup() ->
    try_ok_or_error(fun() -> esp:sleep_enable_gpio_wakeup() end).

light_sleep() ->
    try_ok_or_error(fun() -> esp:light_sleep() end).

deep_sleep() ->
    esp:deep_sleep(),
    nil.

deep_sleep_ms(SleepMS) ->
    esp:deep_sleep(SleepMS),
    nil.

sleep_get_wakeup_cause() ->
    case esp:sleep_get_wakeup_cause() of
        undefined ->
            {ok, none};
        error ->
            {error, failed};
        Cause when is_atom(Cause) ->
            {ok, {some, wrap_wakeup_cause(Cause)}};
        Cause ->
            {ok, {some, {other_cause, iolist_to_binary(io_lib:format("~p", [Cause]))}}}
    end.

sleep_enable_ext0_wakeup(Pin, Level) ->
    try_ok_or_error(fun() -> esp:sleep_enable_ext0_wakeup(Pin, Level) end).

sleep_enable_ext1_wakeup(Mask, Mode) ->
    try_ok_or_error(fun() -> esp:sleep_enable_ext1_wakeup(Mask, Mode) end).

sleep_enable_ext1_wakeup_io(Mask, Mode) ->
    try_ok_or_error(fun() -> esp:sleep_enable_ext1_wakeup_io(Mask, Mode) end).

sleep_disable_ext1_wakeup_io(Mask) ->
    try_ok_or_error(fun() -> esp:sleep_disable_ext1_wakeup_io(Mask) end).

deep_sleep_enable_gpio_wakeup(Mask, Mode) ->
    try_ok_or_error(fun() -> esp:deep_sleep_enable_gpio_wakeup(Mask, Mode) end).

sleep_enable_ulp_wakeup() ->
    try_ok_or_error(fun() -> esp:sleep_enable_ulp_wakeup() end).

sleep_enable_timer_wakeup(SleepUS) ->
    try_ok_or_error(fun() -> esp:sleep_enable_timer_wakeup(SleepUS) end).

partition_list() ->
    try
        {ok, [wrap_partition(P) || P <- esp:partition_list()]}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

partition_read(Id, Offset, Size) ->
    case esp:partition_read(Id, Offset, Size) of
        {ok, Data} ->
            {ok, Data};
        error ->
            {error, failed};
        {error, Reason} ->
            wrap_reason(Reason)
    end.

partition_mmap(Id, Offset, Size) ->
    case esp:partition_mmap(Id, Offset, Size) of
        {ok, Data} ->
            {ok, Data};
        error ->
            {error, failed};
        {error, Reason} ->
            wrap_reason(Reason)
    end.

partition_write(Id, Offset, Data) ->
    try_ok_or_error(fun() -> esp:partition_write(Id, Offset, Data) end).

partition_erase_range(Id, Offset) ->
    try_ok_or_error(fun() -> esp:partition_erase_range(Id, Offset) end).

partition_erase_range_size(Id, Offset, Size) ->
    try_ok_or_error(fun() -> esp:partition_erase_range(Id, Offset, Size) end).

rtc_slow_get_binary() ->
    try
        {ok, esp:rtc_slow_get_binary()}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

rtc_slow_set_binary(Bin) ->
    try
        ok = esp:rtc_slow_set_binary(Bin),
        {ok, nil}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

mount(Source, Target, Filesystem, Options) ->
    try
        case esp:mount(Source, Target, Filesystem, mount_options(Options)) of
            {ok, Mounted} ->
                {ok, Mounted};
            {error, Reason} ->
                wrap_reason(Reason);
            error ->
                {error, failed}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:CatchReason when is_atom(CatchReason) ->
            wrap_reason(CatchReason);
        _:_ ->
            {error, failed}
    end.

umount(Mounted) ->
    try_ok_or_error(fun() -> esp:umount(Mounted) end).

task_wdt_init(TimeoutMS, IdleCoreMask, TriggerPanic) ->
    try_ok_or_error(fun() -> esp:task_wdt_init({TimeoutMS, IdleCoreMask, TriggerPanic}) end).

task_wdt_reconfigure(TimeoutMS, IdleCoreMask, TriggerPanic) ->
    try_ok_or_error(fun() ->
        esp:task_wdt_reconfigure({TimeoutMS, IdleCoreMask, TriggerPanic})
    end).

task_wdt_deinit() ->
    try_ok_or_error(fun() -> esp:task_wdt_deinit() end).

task_wdt_add_user(Username) ->
    try
        case esp:task_wdt_add_user(Username) of
            {ok, Handle} ->
                {ok, Handle};
            {error, Reason} ->
                wrap_reason(Reason);
            error ->
                {error, failed}
        end
    catch
        error:undef ->
            {error, not_supported};
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

task_wdt_reset_user(Handle) ->
    try_ok_or_error(fun() -> esp:task_wdt_reset_user(Handle) end).

task_wdt_delete_user(Handle) ->
    try_ok_or_error(fun() -> esp:task_wdt_delete_user(Handle) end).

wrap_partition({Id, Type, Subtype, Address, Size, _Props}) ->
    {partition, Id, Type, Subtype, Address, Size};
wrap_partition({Id, Type, Subtype, Address, Size}) ->
    {partition, Id, Type, Subtype, Address, Size}.

wrap_wakeup_cause(sleep_wakeup_ext0) ->
    sleep_wakeup_ext0;
wrap_wakeup_cause(sleep_wakeup_ext1) ->
    sleep_wakeup_ext1;
wrap_wakeup_cause(sleep_wakeup_timer) ->
    sleep_wakeup_timer;
wrap_wakeup_cause(sleep_wakeup_touchpad) ->
    sleep_wakeup_touchpad;
wrap_wakeup_cause(sleep_wakeup_ulp) ->
    sleep_wakeup_ulp;
wrap_wakeup_cause(sleep_wakeup_gpio) ->
    sleep_wakeup_gpio;
wrap_wakeup_cause(sleep_wakeup_uart) ->
    sleep_wakeup_uart;
wrap_wakeup_cause(sleep_wakeup_wifi) ->
    sleep_wakeup_wifi;
wrap_wakeup_cause(sleep_wakeup_cocpu) ->
    sleep_wakeup_cocpu;
wrap_wakeup_cause(sleep_wakeup_cocpu_trap_trig) ->
    sleep_wakeup_cocpu_trap_trig;
wrap_wakeup_cause(sleep_wakeup_bt) ->
    sleep_wakeup_bt;
wrap_wakeup_cause(Reason) when is_atom(Reason) ->
    {other_cause, atom_to_binary(Reason, utf8)}.

mount_options(Options) ->
    [mount_option(Opt) || Opt <- Options].

mount_option({spi_host, Host}) when is_binary(Host) ->
    {spi_host, name_atom(Host)};
mount_option({spi_host, Host}) when is_atom(Host) ->
    {spi_host, Host};
mount_option(Opt) ->
    Opt.

try_ok_or_error(Fun) when is_function(Fun, 0) ->
    try
        wrap_ok_or_error(Fun())
    catch
        error:undef ->
            {error, not_supported};
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        error:{error, Thrown} ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

wrap_ok_or_error(ok) ->
    {ok, nil};
wrap_ok_or_error(error) ->
    {error, failed};
wrap_ok_or_error({error, Reason}) ->
    wrap_reason(Reason).

name_atom(Name) when is_binary(Name) ->
    binary_to_atom(Name, utf8);
name_atom(Name) when is_atom(Name) ->
    Name.

wrap_reason(not_supported) ->
    {error, not_supported};
wrap_reason(badarg) ->
    {error, badarg};
wrap_reason(timeout) ->
    {error, timeout};
wrap_reason(not_found) ->
    {error, not_found};
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
