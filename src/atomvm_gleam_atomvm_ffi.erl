-module(atomvm_gleam_atomvm_ffi).
-export([add_avm_pack_file/2, read_priv/2]).

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
