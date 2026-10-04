-module(atomvm_gleam_usb_cdc_ffi).
-export([
    open/1,
    open_default/0,
    write/2,
    read/2,
    read_blocking/1,
    close/1
]).

open(Name) ->
    wrap_usb(usb_cdc:open(Name, [])).

open_default() ->
    wrap_usb(usb_cdc:open([])).

write(Usb, Data) ->
    wrap_ok(usb_cdc:write(Usb, Data)).

read(Usb, TimeoutMs) ->
    case usb_cdc:read(Usb, TimeoutMs) of
        {ok, Data} when is_binary(Data) ->
            {ok, Data};
        {ok, Data} ->
            {ok, iolist_to_binary(Data)};
        {error, Reason} ->
            wrap_reason(Reason);
        error ->
            {error, failed}
    end.

read_blocking(Usb) ->
    case usb_cdc:read(Usb) of
        {ok, Data} when is_binary(Data) ->
            {ok, Data};
        {ok, Data} ->
            {ok, iolist_to_binary(Data)};
        {error, Reason} ->
            wrap_reason(Reason);
        error ->
            {error, failed}
    end.

close(Usb) ->
    wrap_ok(usb_cdc:close(Usb)).

wrap_usb({error, Reason}) ->
    wrap_reason(Reason);
wrap_usb(error) ->
    {error, failed};
wrap_usb(Usb) ->
    {ok, Usb}.

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
