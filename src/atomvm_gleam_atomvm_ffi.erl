-module(atomvm_gleam_atomvm_ffi).
-export([
    add_avm_pack_file/2,
    add_avm_pack_binary/2,
    close_avm_pack/1,
    get_start_beam/1,
    read_priv/2,
    posix_clock_settime/2
]).

add_avm_pack_file(Path, Name) ->
    try
        ok = atomvm:add_avm_pack_file(Path, [{name, name_atom(Name)}]),
        {ok, nil}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{error, Reason} ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

add_avm_pack_binary(AVMData, Name) ->
    try
        case atomvm:add_avm_pack_binary(AVMData, [{name, name_atom(Name)}]) of
            ok ->
                {ok, nil};
            {error, Reason} ->
                wrap_reason(Reason);
            error ->
                {error, failed}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{error, Reason} ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

close_avm_pack(Name) ->
    try
        case atomvm:close_avm_pack(name_atom(Name), []) of
            ok ->
                {ok, nil};
            error ->
                {error, failed};
            {error, Reason} ->
                wrap_reason(Reason)
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

get_start_beam(AVM) ->
    try
        case atomvm:get_start_beam(name_atom(AVM)) of
            {ok, Beam} when is_binary(Beam) ->
                {ok, Beam};
            {error, not_found} ->
                {error, not_found};
            {error, Reason} ->
                wrap_reason(Reason)
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

read_priv(Pack, Path) ->
    try
        case atomvm:read_priv(name_atom(Pack), path_chars(Path)) of
            undefined ->
                {error, undefined};
            Bytes when is_binary(Bytes) ->
                {ok, Bytes}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

posix_clock_settime(ClockId, {Seconds, Nanoseconds}) ->
    try
        case atomvm:posix_clock_settime(clock_id(ClockId), {Seconds, Nanoseconds}) of
            ok ->
                {ok, nil};
            {error, Reason} ->
                wrap_reason(Reason);
            error ->
                {error, failed}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{error, Reason} ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

clock_id(realtime) ->
    realtime.

path_chars(Path) when is_binary(Path) ->
    unicode:characters_to_list(Path);
path_chars(Path) when is_list(Path) ->
    Path.

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
wrap_reason(undefined) ->
    {error, undefined};
wrap_reason(failed) ->
    {error, failed};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
