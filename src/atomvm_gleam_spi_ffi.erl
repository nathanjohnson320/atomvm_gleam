-module(atomvm_gleam_spi_ffi).
-export([open/7, close/1, read_at/4, write_at/5, write/3, write_read/3]).

open(Peripheral, Sclk, Mosi, Miso, Pico, Poci, Devices) ->
    try
        Spi = spi:open(#{
            bus_config => maps:from_list(
                opt(peripheral, Peripheral) ++
                    opt(sclk, Sclk) ++
                    opt(mosi, Mosi) ++
                    opt(miso, Miso) ++
                    opt(pico, Pico) ++
                    opt(poci, Poci)
            ),
            device_config => device_config_map(Devices)
        }),
        {ok, Spi}
    catch
        error:badarg ->
            {error, badarg};
        error:not_supported ->
            {error, not_supported};
        error:timeout ->
            {error, timeout};
        error:Reason when is_atom(Reason) ->
            {error, {other, atom_to_binary(Reason, utf8)}};
        _:_ ->
            {error, failed}
    end.

close(Spi) ->
    wrap_ok(spi:close(Spi)).

read_at(Spi, DeviceName, Address, Len) ->
    wrap_value(spi:read_at(Spi, device_atom(DeviceName), Address, Len)).

write_at(Spi, DeviceName, Address, Len, Data) ->
    wrap_value(spi:write_at(Spi, device_atom(DeviceName), Address, Len, Data)).

write(Spi, DeviceName, Transaction) ->
    wrap_ok(spi:write(Spi, device_atom(DeviceName), transaction_map(Transaction))).

write_read(Spi, DeviceName, Transaction) ->
    wrap_value(
        spi:write_read(Spi, device_atom(DeviceName), transaction_map(Transaction))
    ).

device_config_map(Devices) ->
    maps:from_list([
        {device_atom(Name), device_map(Cs, Clock, Mode, AddrBits, CmdBits)}
     || {device_config, Name, Cs, Clock, Mode, AddrBits, CmdBits} <- Devices
    ]).

device_map(Cs, Clock, Mode, AddrBits, CmdBits) ->
    maps:from_list(
        [{cs, Cs}] ++
            opt(clock_speed_hz, Clock) ++
            opt(mode, Mode) ++
            opt(address_len_bits, AddrBits) ++
            opt(command_len_bits, CmdBits)
    ).

transaction_map({transaction, Command, Address, WriteData, WriteBits, ReadBits}) ->
    maps:from_list(
        opt(command, Command) ++
            opt(address, Address) ++
            opt(write_data, WriteData) ++
            opt(write_bits, WriteBits) ++
            opt(read_bits, ReadBits)
    ).

opt(_Key, none) ->
    [];
opt(Key, {some, Value}) ->
    [{Key, Value}].

device_atom(Name) when is_binary(Name) ->
    binary_to_atom(Name, utf8);
device_atom(Name) when is_atom(Name) ->
    Name.

wrap_ok(ok) ->
    {ok, nil};
wrap_ok(error) ->
    {error, failed};
wrap_ok({error, Reason}) ->
    wrap_reason(Reason).

wrap_value({ok, Value}) ->
    {ok, Value};
wrap_value(error) ->
    {error, failed};
wrap_value({error, Reason}) ->
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
