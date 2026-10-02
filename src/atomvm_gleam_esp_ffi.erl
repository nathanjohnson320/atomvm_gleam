-module(atomvm_gleam_esp_ffi).
-export([
    nvs_get_binary/2,
    nvs_put_binary/3,
    nvs_erase_key/2,
    get_default_mac/0,
    reset_reason/0,
    restart/0,
    sleep_enable_gpio_wakeup/0,
    light_sleep/0
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

get_default_mac() ->
    case esp:get_default_mac() of
        {ok, Mac} ->
            {ok, Mac};
        {error, Reason} ->
            wrap_reason(Reason);
        error ->
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
        Reason when is_atom(Reason) ->
            {other_reason, atom_to_binary(Reason, utf8)};
        Reason ->
            {other_reason, iolist_to_binary(io_lib:format("~p", [Reason]))}
    end.

restart() ->
    esp:restart(),
    nil.

sleep_enable_gpio_wakeup() ->
    wrap_ok_or_error(esp:sleep_enable_gpio_wakeup()).

light_sleep() ->
    wrap_ok_or_error(esp:light_sleep()).

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
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
