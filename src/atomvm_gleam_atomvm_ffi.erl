-module(atomvm_gleam_atomvm_ffi).
-export([
    add_avm_pack_file/2,
    add_avm_pack_binary/2,
    close_avm_pack/1,
    get_start_beam/1,
    read_priv/2,
    posix_clock_settime/2,
    posix_open/2,
    posix_open_mode/3,
    posix_close/1,
    posix_read/2,
    posix_write/2,
    posix_select_read/3,
    posix_select_write/3,
    posix_select_stop/1,
    posix_seek/3,
    posix_pread/3,
    posix_pwrite/3,
    posix_fsync/1,
    posix_ftruncate/2,
    posix_mkfifo/2,
    posix_mkdir/2,
    posix_unlink/1,
    posix_rmdir/1,
    posix_rename/2,
    posix_stat/1,
    posix_fstat/1,
    posix_opendir/1,
    posix_closedir/1,
    posix_readdir/1,
    subprocess/4,
    posix_kill/2,
    posix_tcgetattr/1,
    posix_tcsetattr/3,
    posix_tcflush/2
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
        wrap_ok(atomvm:add_avm_pack_binary(AVMData, [{name, name_atom(Name)}]))
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
        wrap_ok(atomvm:close_avm_pack(name_atom(Name), []))
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
            Other ->
                wrap_ok(Other)
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
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
        wrap_ok(
            atomvm:posix_clock_settime(clock_id(ClockId), {Seconds, Nanoseconds})
        )
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

posix_open(Path, Flags) ->
    try
        wrap_value(atomvm:posix_open(Path, open_flags(Flags)))
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

posix_open_mode(Path, Flags, Mode) ->
    try
        wrap_value(atomvm:posix_open(Path, open_flags(Flags), Mode))
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

posix_close(File) ->
    try
        wrap_ok(atomvm:posix_close(File))
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

posix_read(File, Count) ->
    try
        wrap_eof(atomvm:posix_read(File, Count))
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

posix_write(File, Data) ->
    try
        wrap_value(atomvm:posix_write(File, Data))
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

posix_select_read(File, Pid, Ref) ->
    try
        ok = atomvm:posix_select_read(File, Pid, select_ref(Ref)),
        {ok, nil}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

posix_select_write(File, Pid, Ref) ->
    try
        ok = atomvm:posix_select_write(File, Pid, select_ref(Ref)),
        {ok, nil}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

posix_select_stop(File) ->
    try
        ok = atomvm:posix_select_stop(File),
        {ok, nil}
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

posix_seek(File, Offset, Whence) ->
    try
        wrap_value(atomvm:posix_seek(File, Offset, whence(Whence)))
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

posix_pread(File, Count, Offset) ->
    try
        wrap_eof(atomvm:posix_pread(File, Count, Offset))
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

posix_pwrite(File, Data, Offset) ->
    try
        wrap_value(atomvm:posix_pwrite(File, Data, Offset))
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

posix_fsync(File) ->
    try
        wrap_ok(atomvm:posix_fsync(File))
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

posix_ftruncate(File, Length) ->
    try
        wrap_ok(atomvm:posix_ftruncate(File, Length))
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

posix_mkfifo(Path, Mode) ->
    try
        wrap_ok(atomvm:posix_mkfifo(Path, Mode))
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

posix_mkdir(Path, Mode) ->
    try
        wrap_ok(atomvm:posix_mkdir(Path, Mode))
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

posix_unlink(Path) ->
    try
        wrap_ok(atomvm:posix_unlink(Path))
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

posix_rmdir(Path) ->
    try
        wrap_ok(atomvm:posix_rmdir(Path))
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

posix_rename(OldPath, NewPath) ->
    try
        wrap_ok(atomvm:posix_rename(OldPath, NewPath))
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

posix_stat(Path) ->
    try
        case atomvm:posix_stat(Path) of
            {ok, Info} when is_map(Info) ->
                {ok, stat_info(Info)};
            Other ->
                wrap_ok(Other)
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

posix_fstat(File) ->
    try
        case atomvm:posix_fstat(File) of
            {ok, Info} when is_map(Info) ->
                {ok, stat_info(Info)};
            Other ->
                wrap_ok(Other)
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

posix_opendir(Path) ->
    try
        wrap_value(atomvm:posix_opendir(Path))
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

posix_closedir(Dir) ->
    try
        wrap_ok(atomvm:posix_closedir(Dir))
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

posix_readdir(Dir) ->
    try
        case atomvm:posix_readdir(Dir) of
            {ok, {dirent, Inode, Name}} ->
                {ok, {some, {posix_dirent, Inode, Name}}};
            eof ->
                {ok, none};
            {error, Err} ->
                wrap_reason(Err);
            error ->
                {error, failed}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        error:{error, Thrown} ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

subprocess(Path, Args, Env, Options) ->
    try
        case atomvm:subprocess(Path, Args, env_list(Env), Options) of
            {ok, OsPid, Fd} ->
                {ok, {OsPid, Fd}};
            {error, Err} ->
                wrap_reason(Err);
            error ->
                {error, failed}
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Thrown when is_atom(Thrown) ->
            wrap_reason(Thrown);
        error:{error, Thrown} ->
            wrap_reason(Thrown);
        _:_ ->
            {error, failed}
    end.

posix_kill(OsPid, Signal) ->
    try
        wrap_ok(atomvm:posix_kill(OsPid, Signal))
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

posix_tcgetattr(File) ->
    try
        case atomvm:posix_tcgetattr(File) of
            {ok, Info} when is_map(Info) ->
                {ok, termios_from_map(Info)};
            Other ->
                wrap_ok(Other)
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

posix_tcsetattr(File, ApplyWhen, Termios) ->
    try
        wrap_ok(
            atomvm:posix_tcsetattr(
                File, tcsetattr_when(ApplyWhen), termios_to_map(Termios)
            )
        )
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

posix_tcflush(File, QueueSelector) ->
    try
        wrap_ok(atomvm:posix_tcflush(File, tcflush_queue(QueueSelector)))
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

tcsetattr_when(tcsanow) -> tcsanow;
tcsetattr_when(tcsadrain) -> tcsadrain;
tcsetattr_when(tcsaflush) -> tcsaflush.

tcflush_queue(tciflush) -> tciflush;
tcflush_queue(tcoflush) -> tcoflush;
tcflush_queue(tcioflush) -> tcioflush.

termios_from_map(Map) when is_map(Map) ->
    {posix_termios, map_opt(Map, cflag), map_opt(Map, iflag), map_opt(Map, oflag),
        map_opt(Map, lflag), map_opt(Map, ispeed), map_opt(Map, ospeed),
        map_opt(Map, raw), map_opt(Map, data_bits), map_opt(Map, stop_bits),
        map_parity_opt(Map), map_flow_opt(Map), map_opt(Map, clocal)}.

termios_to_map(
    {posix_termios, Cflag, Iflag, Oflag, Lflag, Ispeed, Ospeed, Raw, DataBits,
        StopBits, Parity, FlowControl, Clocal}
) ->
    maps:from_list(
        opt_kv(cflag, Cflag) ++
            opt_kv(iflag, Iflag) ++
            opt_kv(oflag, Oflag) ++
            opt_kv(lflag, Lflag) ++
            opt_kv(ispeed, Ispeed) ++
            opt_kv(ospeed, Ospeed) ++
            opt_kv(raw, Raw) ++
            opt_kv(data_bits, DataBits) ++
            opt_kv(stop_bits, StopBits) ++
            parity_kv(Parity) ++
            flow_kv(FlowControl) ++
            opt_kv(clocal, Clocal)
    ).

map_opt(Map, Key) ->
    case maps:find(Key, Map) of
        {ok, Value} ->
            {some, Value};
        error ->
            none
    end.

map_parity_opt(Map) ->
    case maps:find(parity, Map) of
        {ok, none} ->
            {some, no_parity};
        {ok, even} ->
            {some, even};
        {ok, odd} ->
            {some, odd};
        {ok, _} ->
            none;
        error ->
            none
    end.

map_flow_opt(Map) ->
    case maps:find(flow_control, Map) of
        {ok, none} ->
            {some, no_flow};
        {ok, hardware} ->
            {some, hardware};
        {ok, software} ->
            {some, software};
        {ok, _} ->
            none;
        error ->
            none
    end.

opt_kv(_Key, none) ->
    [];
opt_kv(Key, {some, Value}) ->
    [{Key, Value}].

parity_kv(none) ->
    [];
parity_kv({some, no_parity}) ->
    [{parity, none}];
parity_kv({some, even}) ->
    [{parity, even}];
parity_kv({some, odd}) ->
    [{parity, odd}].

flow_kv(none) ->
    [];
flow_kv({some, no_flow}) ->
    [{flow_control, none}];
flow_kv({some, hardware}) ->
    [{flow_control, hardware}];
flow_kv({some, software}) ->
    [{flow_control, software}].

open_flags(Flags) when is_list(Flags) ->
    [open_flag(F) || F <- Flags].

%% Gleam encodes ORdonly as o_rdonly, etc. Remap only if needed; identity for
%% known upstream atoms and Gleam snake_case constructors.
open_flag(o_exec) -> o_exec;
open_flag(o_rdonly) -> o_rdonly;
open_flag(o_rdwr) -> o_rdwr;
open_flag(o_search) -> o_search;
open_flag(o_wronly) -> o_wronly;
open_flag(o_append) -> o_append;
open_flag(o_cloexec) -> o_cloexec;
open_flag(o_creat) -> o_creat;
open_flag(o_directory) -> o_directory;
open_flag(o_dsync) -> o_dsync;
open_flag(o_excl) -> o_excl;
open_flag(o_noctty) -> o_noctty;
open_flag(o_nofollow) -> o_nofollow;
open_flag(o_rsync) -> o_rsync;
open_flag(o_sync) -> o_sync;
open_flag(o_trunc) -> o_trunc;
open_flag(o_tty_atom) -> o_tty_atom;
open_flag(Flag) when is_atom(Flag) -> Flag.

whence(seek_set) -> seek_set;
whence(seek_cur) -> seek_cur;
whence(seek_end) -> seek_end.

select_ref(none) ->
    undefined;
select_ref({some, Ref}) ->
    Ref;
select_ref(undefined) ->
    undefined;
select_ref(Ref) ->
    Ref.

env_list(none) ->
    undefined;
env_list({some, Env}) when is_list(Env) ->
    Env;
env_list(undefined) ->
    undefined;
env_list(Env) when is_list(Env) ->
    Env.

stat_info(#{
    st_dev := Dev,
    st_ino := Ino,
    st_mode := Mode,
    st_nlink := Nlink,
    st_uid := Uid,
    st_gid := Gid,
    st_size := Size,
    st_atime_s := Atime,
    st_mtime_s := Mtime,
    st_ctime_s := Ctime
}) ->
    {posix_stat_info, Dev, Ino, Mode, Nlink, Uid, Gid, Size, Atime, Mtime, Ctime}.

path_chars(Path) when is_binary(Path) ->
    unicode:characters_to_list(Path);
path_chars(Path) when is_list(Path) ->
    Path.

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

wrap_value({ok, Value}) ->
    {ok, Value};
wrap_value(error) ->
    {error, failed};
wrap_value({error, Reason}) ->
    wrap_reason(Reason).

wrap_eof({ok, Value}) ->
    {ok, {some, Value}};
wrap_eof(eof) ->
    {ok, none};
wrap_eof(error) ->
    {error, failed};
wrap_eof({error, Reason}) ->
    wrap_reason(Reason).

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
wrap_reason(Reason) when is_integer(Reason) ->
    {error, {other, integer_to_binary(Reason)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
