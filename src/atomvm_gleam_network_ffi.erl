-module(atomvm_gleam_network_ffi).
-export([
    start/8,
    sta_connect/0,
    sta_connect_to/2,
    sta_disconnect/0,
    wifi_scan/1,
    wait_for_sta/3,
    stop/0
]).

start(Managed, Ssid, Psk, DhcpHostname, Notify, SntpEnabled, SntpHost, SntpNotify) ->
    Sta =
        maybe_managed(Managed) ++
            opt(ssid, Ssid) ++
            opt(psk, Psk) ++
            opt(dhcp_hostname, DhcpHostname) ++
            [
                {scan_done, Notify},
                {connected, fun() -> Notify ! connected end},
                {got_ip, fun(Info) -> Notify ! {got_ip, Info} end},
                {disconnected, fun() -> Notify ! disconnected end}
            ],
    Config =
        case SntpEnabled of
            true ->
                [
                    {sta, Sta},
                    {sntp, [
                        {host, SntpHost},
                        {synchronized, fun(Timeval) ->
                            SntpNotify ! {synchronized, Timeval}
                        end}
                    ]}
                ];
            false ->
                [{sta, Sta}]
        end,
    case network:start(Config) of
        {ok, _Pid} ->
            {ok, nil};
        ok ->
            {ok, nil};
        {error, Reason} ->
            wrap_reason(Reason);
        error ->
            {error, failed}
    end.

sta_connect() ->
    wrap_ok(network:sta_connect()).

sta_connect_to(Ssid, Psk) ->
    wrap_ok(network:sta_connect([{ssid, Ssid}, {psk, Psk}])).

sta_disconnect() ->
    wrap_ok(network:sta_disconnect()).

wifi_scan(Results) ->
    wrap_ok(network:wifi_scan([{results, Results}])).

wait_for_sta(Ssid, Psk, TimeoutMs) ->
    Config = [{ssid, Ssid}, {psk, Psk}],
    case network:wait_for_sta(Config, TimeoutMs) of
        {ok, {Address, Netmask, Gateway}} ->
            {ok, {ip_info, ipv4(Address), ipv4(Netmask), ipv4(Gateway)}};
        {error, Reason} ->
            wrap_reason(Reason);
        error ->
            {error, failed}
    end.

stop() ->
    wrap_ok(network:stop()).

maybe_managed(true) ->
    [managed];
maybe_managed(false) ->
    [].

opt(_Key, none) ->
    [];
opt(Key, {some, Value}) ->
    [{Key, Value}].

ipv4({A, B, C, D}) ->
    {ipv4_address, A, B, C, D}.

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
wrap_reason(disconnected) ->
    {error, disconnected};
wrap_reason(failed) ->
    {error, failed};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
