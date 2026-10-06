-module(atomvm_gleam_avm_pubsub_ffi).
-export([start/0, start_named/1, publish/3, sub/2, sub_pid/3, unsub/2, unsub_pid/3]).

start() ->
    try
        case avm_pubsub:start() of
            {ok, Pid} ->
                {ok, Pid};
            {error, Reason} ->
                wrap_reason(Reason);
            error ->
                {error, failed}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

start_named(Name) ->
    try
        case avm_pubsub:start(name_atom(Name)) of
            {ok, Pid} ->
                {ok, Pid};
            {error, Reason} ->
                wrap_reason(Reason);
            error ->
                {error, failed}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

publish(PubSub, Topic, Term) ->
    try
        case avm_pubsub:pub(PubSub, Topic, Term) of
            {ok, Count} ->
                {ok, Count};
            {error, Reason} ->
                wrap_reason(Reason);
            error ->
                {error, failed}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

sub(PubSub, Topic) ->
    try
        wrap_ok(avm_pubsub:sub(PubSub, Topic))
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

sub_pid(PubSub, Topic, Pid) ->
    try
        wrap_ok(avm_pubsub:sub(PubSub, Topic, Pid))
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

unsub(PubSub, Topic) ->
    try
        wrap_ok(avm_pubsub:unsub(PubSub, Topic))
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

unsub_pid(PubSub, Topic, Pid) ->
    try
        wrap_ok(avm_pubsub:unsub(PubSub, Topic, Pid))
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

name_atom(Name) when is_binary(Name) ->
    binary_to_atom(Name, utf8);
name_atom(Name) when is_atom(Name) ->
    Name.

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
wrap_reason(failed) ->
    {error, failed};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
