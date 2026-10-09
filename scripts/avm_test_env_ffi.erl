-module(avm_test_env_ffi).
-export([
    try_random/0,
    getenv/1,
    sleep_ms/1,
    receive_any/1,
    receive_gpio_interrupt/2,
    try_socat_ptys/0,
    stop_socat/1
]).

%% Soft-call atomvm:random/0 — some builds omit the NIF.
try_random() ->
    try
        {ok, atomvm:random()}
    catch
        error:undef ->
            {error, nil};
        error:not_supported ->
            {error, nil};
        _:_ ->
            {error, nil}
    end.

%% Gleam `Option(String)` ↔ `none` / `{some, Binary}`.
getenv(Name) when is_binary(Name) ->
    getenv(unicode:characters_to_list(Name));
getenv(Name) when is_list(Name) ->
    case os:getenv(Name) of
        false ->
            none;
        Value when is_list(Value) ->
            {some, unicode:characters_to_binary(Value)};
        Value when is_binary(Value) ->
            {some, Value}
    end;
getenv(_Name) ->
    none.

sleep_ms(Ms) when is_integer(Ms), Ms >= 0 ->
    timer:sleep(Ms),
    nil.

%% Timed mailbox receive for active-mode HTTP / GPIO interrupt tests.
receive_any(TimeoutMs) when is_integer(TimeoutMs), TimeoutMs >= 0 ->
    receive
        Msg ->
            {ok, Msg}
    after TimeoutMs ->
        {error, timeout}
    end.

%% Wait for `{gpio_interrupt, Pin}` (Pin is the integer GPIO number).
receive_gpio_interrupt(Pin, TimeoutMs) when is_integer(Pin), is_integer(TimeoutMs), TimeoutMs >= 0 ->
    receive
        {gpio_interrupt, Pin} ->
            {ok, Pin};
        {gpio_interrupt, Other} ->
            {error, <<"other_pin:", (integer_to_binary(Other))/binary>>}
    after TimeoutMs ->
        {error, <<"timeout">>}
    end.

%% Start `socat` pty pair for UART loopback. Returns
%% `{ok, {Handle, PtyA, PtyB}}` where Handle is `{OsPid, Fd}` for stop_socat/1.
try_socat_ptys() ->
    try
        case has_socat() of
            false ->
                {error, <<"no_socat">>};
            true ->
                case has_working_ptys() of
                    false ->
                        {error, <<"no_pty">>};
                    true ->
                        {Handle, PtyA, PtyB} = start_socat(),
                        {ok, {Handle, PtyA, PtyB}}
                end
        end
    catch
        error:Reason when is_atom(Reason) ->
            {error, atom_to_binary(Reason, utf8)};
        error:{error, Reason} when is_atom(Reason) ->
            {error, atom_to_binary(Reason, utf8)};
        Class:Reason ->
            {error,
                iolist_to_binary(
                    io_lib:format("~p:~p", [Class, Reason])
                )}
    end.

stop_socat({OsPid, Fd}) when is_integer(OsPid) ->
    case atomvm:posix_kill(OsPid, 15) of
        ok ->
            ok;
        {error, esrch} ->
            ok;
        {error, _} ->
            ok
    end,
    _ = atomvm:posix_close(Fd),
    nil;
stop_socat(_) ->
    nil.

has_socat() ->
    try
        {ok, _, Fd} = atomvm:subprocess(
            "/bin/sh", ["sh", "-c", "command -v socat"], undefined, [stdout]
        ),
        Result =
            case atomvm:posix_read(Fd, 200) of
                eof ->
                    false;
                {ok, _} ->
                    true;
                {error, _} ->
                    false
            end,
        ok = atomvm:posix_close(Fd),
        Result
    catch
        _:_ ->
            false
    end.

has_working_ptys() ->
    with_socat_check(fun(PtyA) ->
        case atomvm:posix_open(PtyA, [o_rdwr, o_noctty]) of
            {ok, Fd} ->
                try
                    case atomvm:posix_tcgetattr(Fd) of
                        {ok, _} ->
                            true;
                        {error, _} ->
                            false
                    end
                after
                    atomvm:posix_close(Fd)
                end;
            {error, _} ->
                false
        end
    end).

with_socat_check(Fun) ->
    {Handle, PtyA, _PtyB} = start_socat(),
    try
        Fun(PtyA)
    after
        stop_socat(Handle)
    end.

start_socat() ->
    {ok, OsPid, Fd} = atomvm:subprocess(
        "/bin/sh",
        ["sh", "-c", "exec socat -d -d pty,raw,echo=0 pty,raw,echo=0 2>&1"],
        undefined,
        [stdout]
    ),
    PtyA = read_pty_path(Fd),
    PtyB = read_pty_path(Fd),
    receive
    after 200 ->
        ok
    end,
    {{OsPid, Fd}, PtyA, PtyB}.

read_pty_path(Fd) ->
    read_pty_path(Fd, <<>>).

read_pty_path(Fd, Acc) ->
    case atomvm:posix_read(Fd, 1) of
        {ok, <<$\n>>} ->
            extract_pty(Acc);
        {ok, Byte} ->
            read_pty_path(Fd, <<Acc/binary, Byte/binary>>);
        {error, eagain} ->
            ok = atomvm:posix_select_read(Fd, self(), undefined),
            receive
                {select, _FdRes, undefined, ready_input} ->
                    ok
            after 5000 ->
                error(socat_read_timeout)
            end,
            read_pty_path(Fd, Acc);
        eof ->
            error({unexpected_socat_eof, Acc});
        {error, Reason} ->
            error({socat_read, Reason})
    end.

extract_pty(Line) ->
    case binary:match(Line, <<"PTY is ">>) of
        {Pos, Len} ->
            binary:part(Line, Pos + Len, byte_size(Line) - Pos - Len);
        nomatch ->
            error({unexpected_socat_output, Line})
    end.
