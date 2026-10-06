-module(atomvm_gleam_json_ffi).
-export([
    encode/1,
    encode_with/2,
    decode/1,
    decode_with/3,
    decode_start/3,
    decode_continue/2,
    default_encoder/0,
    default_decoders/0,
    encode_value/2,
    encode_atom/2,
    encode_binary/1,
    encode_binary_escape_all/1,
    encode_float/1,
    encode_integer/1,
    encode_list/2,
    encode_map/2,
    encode_map_checked/2,
    encode_key_value_list/2,
    encode_key_value_list_checked/2
]).

%% Default OTP encoder used by `json:encode/1`.
default_encoder() ->
    fun json:encode_value/2.

%% Empty map → OTP built-in decoder callbacks.
default_decoders() ->
    #{}.

encode(Term) ->
    try_iodata(fun() -> json:encode(Term) end).

encode_with(Term, Encoder) ->
    try_iodata(fun() -> json:encode(Term, Encoder) end).

encode_value(Term, Encoder) ->
    try_iodata(fun() -> json:encode_value(Term, Encoder) end).

encode_atom(Atom, Encoder) ->
    try_iodata(fun() -> json:encode_atom(Atom, Encoder) end).

encode_binary(Bin) ->
    try_iodata(fun() -> json:encode_binary(Bin) end).

encode_binary_escape_all(Bin) ->
    try_iodata(fun() -> json:encode_binary_escape_all(Bin) end).

encode_float(Float) ->
    try_iodata(fun() -> json:encode_float(Float) end).

encode_integer(Int) ->
    try_iodata(fun() -> json:encode_integer(Int) end).

encode_list(List, Encoder) ->
    try_iodata(fun() -> json:encode_list(List, Encoder) end).

encode_map(Map, Encoder) ->
    try_iodata(fun() -> json:encode_map(Map, Encoder) end).

encode_map_checked(Map, Encoder) ->
    try_iodata(fun() -> json:encode_map_checked(Map, Encoder) end).

encode_key_value_list(List, Encoder) ->
    try_iodata(fun() -> json:encode_key_value_list(List, Encoder) end).

encode_key_value_list_checked(List, Encoder) ->
    try_iodata(fun() -> json:encode_key_value_list_checked(List, Encoder) end).

decode(Bytes) ->
    try
        {ok, json:decode(Bytes)}
    catch
        Class:Reason ->
            wrap_exception(Class, Reason)
    end.

decode_with(Bytes, Acc, Decoders) ->
    try
        {Value, Acc1, Rest} = json:decode(Bytes, Acc, Decoders),
        {ok, {Value, Acc1, Rest}}
    catch
        Class:Reason ->
            wrap_exception(Class, Reason)
    end.

decode_start(Bytes, Acc, Decoders) ->
    try
        case json:decode_start(Bytes, Acc, Decoders) of
            {continue, State} ->
                {ok, {need_more, State}};
            {Value, Acc1, Rest} ->
                {ok, {complete, Value, Acc1, Rest}}
        end
    catch
        Class:Reason ->
            wrap_exception(Class, Reason)
    end.

decode_continue(Input, State) ->
    Chunk =
        case Input of
            end_of_input ->
                end_of_input;
            {bytes, Bin} ->
                Bin
        end,
    try
        case json:decode_continue(Chunk, State) of
            {continue, State1} ->
                {ok, {need_more, State1}};
            {Value, Acc1, Rest} ->
                {ok, {complete, Value, Acc1, Rest}}
        end
    catch
        Class:Reason ->
            wrap_exception(Class, Reason)
    end.

%% ---------------------------------------------------------------------------

try_iodata(Fun) ->
    try
        {ok, iolist_to_binary(Fun())}
    catch
        Class:Reason ->
            wrap_exception(Class, Reason)
    end.

wrap_exception(error, badarg) ->
    {error, badarg};
wrap_exception(error, Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_exception(error, {Reason, _}) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_exception(_, _) ->
    {error, failed}.
