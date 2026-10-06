-module(atomvm_gleam_network_ffi).
-export([
    start/19,
    sta_connect/0,
    sta_connect_to/2,
    sta_disconnect/0,
    wifi_scan/0,
    wifi_scan/1,
    wait_for_sta_default/0,
    wait_for_sta_timeout/1,
    wait_for_sta_config/2,
    wait_for_sta/3,
    wait_for_ap_default/0,
    wait_for_ap/3,
    sta_rssi/0,
    sta_status/0,
    stop/0
]).

start(
    StaEnabled,
    Managed,
    Ssid,
    Psk,
    DhcpHostname,
    StaNotify,
    ApEnabled,
    ApSsid,
    ApPsk,
    ApChannel,
    ApSsidHidden,
    ApMaxConnections,
    ApNotify,
    SntpEnabled,
    SntpHost,
    SntpNotify,
    MdnsEnabled,
    MdnsHost,
    MdnsTtl
) ->
    Config =
        maybe_sta(StaEnabled, Managed, Ssid, Psk, DhcpHostname, StaNotify) ++
            maybe_ap(
                ApEnabled,
                ApSsid,
                ApPsk,
                ApChannel,
                ApSsidHidden,
                ApMaxConnections,
                ApNotify
            ) ++
            maybe_sntp(SntpEnabled, SntpHost, SntpNotify) ++
            maybe_mdns(MdnsEnabled, MdnsHost, MdnsTtl),
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

wifi_scan() ->
    wrap_ok(network:wifi_scan()).

wifi_scan(Results) ->
    wrap_ok(network:wifi_scan([{results, Results}])).

wait_for_sta_default() ->
    wrap_wait_for_sta(network:wait_for_sta()).

wait_for_sta_timeout(TimeoutMs) ->
    wrap_wait_for_sta(network:wait_for_sta(TimeoutMs)).

wait_for_sta_config(Ssid, Psk) ->
    Config = opt(ssid, Ssid) ++ opt(psk, Psk),
    wrap_wait_for_sta(network:wait_for_sta(Config)).

wait_for_sta(Ssid, Psk, TimeoutMs) ->
    Config = [{ssid, Ssid}, {psk, Psk}],
    wrap_wait_for_sta(network:wait_for_sta(Config, TimeoutMs)).

wait_for_ap_default() ->
    wrap_ok(network:wait_for_ap()).

wait_for_ap(Ssid, Psk, TimeoutMs) ->
    Config = opt(ssid, Ssid) ++ opt(psk, Psk),
    case network:wait_for_ap(Config, TimeoutMs) of
        ok ->
            {ok, nil};
        {error, Reason} ->
            wrap_reason(Reason);
        error ->
            {error, failed}
    end.

sta_rssi() ->
    case network:sta_rssi() of
        {ok, Dbm} when is_integer(Dbm) ->
            {ok, Dbm};
        {error, Reason} ->
            wrap_reason(Reason);
        error ->
            {error, failed}
    end.

sta_status() ->
    try network:sta_status() of
        associated ->
            {ok, sta_associated};
        connected ->
            {ok, sta_connected};
        connecting ->
            {ok, sta_connecting};
        degraded ->
            {ok, sta_degraded};
        disconnected ->
            {ok, sta_disconnected};
        disconnecting ->
            {ok, sta_disconnecting};
        inactive ->
            {ok, sta_inactive};
        Other ->
            wrap_reason(Other)
    catch
        exit:{noproc, _} ->
            {error, {other, <<"network_down">>}};
        exit:{timeout, _} ->
            {error, timeout};
        exit:Reason ->
            wrap_reason(Reason);
        error:badarg ->
            {error, badarg};
        error:Reason ->
            wrap_reason(Reason)
    end.

stop() ->
    wrap_ok(network:stop()).

maybe_sta(false, _Managed, _Ssid, _Psk, _DhcpHostname, _Notify) ->
    [];
maybe_sta(true, Managed, Ssid, Psk, DhcpHostname, Notify) ->
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
    [{sta, Sta}].

maybe_ap(false, _Ssid, _Psk, _Channel, _SsidHidden, _MaxConnections, _Notify) ->
    [];
maybe_ap(true, Ssid, Psk, Channel, SsidHidden, MaxConnections, Notify) ->
    Ap =
        opt(ssid, Ssid) ++
            opt(psk, Psk) ++
            opt(ap_channel, Channel) ++
            opt(ap_ssid_hidden, SsidHidden) ++
            opt(ap_max_connections, MaxConnections) ++
            [
                {ap_started, fun() -> Notify ! ap_started end},
                {sta_connected, fun(Mac) -> Notify ! {sta_connected, Mac} end},
                {sta_disconnected, fun(Mac) -> Notify ! {sta_disconnected, Mac} end},
                {sta_ip_assigned, fun(Address) ->
                    Notify ! {sta_ip_assigned, Address}
                end}
            ],
    [{ap, Ap}].

maybe_sntp(false, _Host, _Notify) ->
    [];
maybe_sntp(true, Host, Notify) ->
    [
        {sntp, [
            {host, Host},
            {synchronized, fun(Timeval) ->
                Notify ! {synchronized, Timeval}
            end}
        ]}
    ].

maybe_mdns(false, _Host, _Ttl) ->
    [];
maybe_mdns(true, Host, Ttl) ->
    [{mdns, [{host, Host}] ++ opt(ttl, Ttl)}].

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

wrap_wait_for_sta({ok, {Address, Netmask, Gateway}}) ->
    {ok, {ip_info, ipv4(Address), ipv4(Netmask), ipv4(Gateway)}};
wrap_wait_for_sta({error, Reason}) ->
    wrap_reason(Reason);
wrap_wait_for_sta(error) ->
    {error, failed}.

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
