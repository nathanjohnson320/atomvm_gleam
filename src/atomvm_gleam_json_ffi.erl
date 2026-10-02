-module(atomvm_gleam_json_ffi).
-export([encode/1, decode/1]).

encode(Term) ->
    try
        {ok, iolist_to_binary(json:encode(Term))}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            {error, {other, atom_to_binary(Reason, utf8)}};
        _:_ ->
            {error, failed}
    end.

decode(Bytes) ->
    try
        {ok, json:decode(Bytes)}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            {error, {other, atom_to_binary(Reason, utf8)}};
        _:_ ->
            {error, failed}
    end.
