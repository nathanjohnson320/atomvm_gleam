-module(atomvm_gleam_uart_ffi).
-export([
    open/11,
    open_default/10,
    write/2,
    read/2,
    close/1
]).

open(Name, Tx, Rx, Rts, Cts, Speed, DataBits, StopBits, EventQueueLen, Flow, Parity) ->
    try
        wrap_uart(
            uart:open(
                Name,
                opts(Tx, Rx, Rts, Cts, Speed, DataBits, StopBits, EventQueueLen, Flow, Parity)
            )
        )
    catch
        error:Thrown ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

open_default(Tx, Rx, Rts, Cts, Speed, DataBits, StopBits, EventQueueLen, Flow, Parity) ->
    try
        wrap_uart(
            uart:open(opts(Tx, Rx, Rts, Cts, Speed, DataBits, StopBits, EventQueueLen, Flow, Parity))
        )
    catch
        error:Thrown ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

write(Uart, Data) ->
    try
        wrap_ok(uart:write(Uart, Data))
    catch
        error:Thrown ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

read(Uart, TimeoutMs) ->
    try
        case uart:read(Uart, TimeoutMs) of
            {ok, Data} when is_binary(Data) ->
                {ok, Data};
            {ok, Data} ->
                {ok, iolist_to_binary(Data)};
            {error, Reason} ->
                wrap_reason(Reason);
            error ->
                {error, failed}
        end
    catch
        error:Thrown ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

close(Uart) ->
    try
        wrap_ok(uart:close(Uart))
    catch
        error:Thrown ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

opts(Tx, Rx, Rts, Cts, Speed, DataBits, StopBits, EventQueueLen, Flow, Parity) ->
    opt(tx, Tx) ++
        opt(rx, Rx) ++
        opt(rts, Rts) ++
        opt(cts, Cts) ++
        opt(speed, Speed) ++
        opt(data_bits, DataBits) ++
        opt(stop_bits, StopBits) ++
        opt(event_queue_len, EventQueueLen) ++
        flow_opt(Flow) ++
        parity_opt(Parity).

flow_opt(none) ->
    [];
flow_opt({some, no_flow}) ->
    [{flow_control, none}];
flow_opt({some, hardware}) ->
    [{flow_control, hardware}];
flow_opt({some, software}) ->
    [{flow_control, software}].

parity_opt(none) ->
    [];
parity_opt({some, no_parity}) ->
    [{parity, none}];
parity_opt({some, even}) ->
    [{parity, even}];
parity_opt({some, odd}) ->
    [{parity, odd}].

opt(_Key, none) ->
    [];
opt(Key, {some, Value}) ->
    [{Key, Value}].

wrap_uart({error, Reason}) ->
    wrap_reason(Reason);
wrap_uart(error) ->
    {error, failed};
wrap_uart(Uart) ->
    {ok, Uart}.

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
wrap_reason(ealready) ->
    {error, ealready};
wrap_reason(failed) ->
    {error, failed};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
