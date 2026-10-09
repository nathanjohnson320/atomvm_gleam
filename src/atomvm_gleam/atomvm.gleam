/// AtomVM platform helpers (`atomvm` module).
///
/// See [Module atomvm](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html).
///
/// Upstream source:
/// [atomvm.erl](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/atomvm.erl#L1).
///
/// Note: AtomVM's `rand_bytes/1` is deprecated in favor of
/// `crypto:strong_rand_bytes/1`. Prefer a crypto wrapper when available; this
/// module does not wrap the deprecated API.
///
/// POSIX file, directory, subprocess, and termios APIs below are
/// **platform-dependent**. They are typically available on `generic_unix` and
/// MCU / UART builds that expose the corresponding NIFs. Missing NIFs surface
/// as `Error(Undefined)` (upstream `erlang:nif_error(undefined)`), not
/// `NotSupported`.
import gleam/erlang/process.{type Pid}
import gleam/erlang/reference.{type Reference}
import gleam/option.{type Option}

/// Errors from AtomVM platform helpers.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  NotFound
  Undefined
  Other(String)
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    NotFound -> "not_found"
    Undefined -> "undefined"
    Other(reason) -> reason
  }
}

/// AtomVM platform moniker returned by [`platform`](#platform).
///
/// See [`atomvm:platform/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#platform-0).
pub type Platform {
  GenericUnix
  Emscripten
  Esp32
  Pico
  Stm32
}

/// Return the platform moniker for the running AtomVM build.
///
/// See [`atomvm:platform/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#platform-0).
@external(erlang, "atomvm", "platform")
pub fn platform() -> Platform

/// Mount an AVM pack file (or ESP32 partition path) under `name`.
///
/// On ESP32, `path` is typically `"/dev/partition/by-name/assets.avm"`.
/// `name` becomes the Erlang atom used with [`read_priv`](#read_priv).
///
/// See [`atomvm:add_avm_pack_file/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#add-avm-pack-file-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "add_avm_pack_file")
pub fn add_avm_pack_file(path: String, name: String) -> Result(Nil, Error)

/// Mount AVM pack data from a binary under `name`.
///
/// See [`atomvm:add_avm_pack_binary/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#add-avm-pack-binary-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "add_avm_pack_binary")
pub fn add_avm_pack_binary(
  avm_data: BitArray,
  name: String,
) -> Result(Nil, Error)

/// Close a previously mounted AVM pack referenced by `name`.
///
/// See [`atomvm:close_avm_pack/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#close-avm-pack-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "close_avm_pack")
pub fn close_avm_pack(name: String) -> Result(Nil, Error)

/// Return the start beam module name (with suffix) for a mounted AVM pack.
///
/// See [`atomvm:get_start_beam/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#get-start-beam-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "get_start_beam")
pub fn get_start_beam(avm: String) -> Result(BitArray, Error)

/// Read a `priv/` resource from a previously mounted AVM pack.
///
/// `path` is a filesystem-style path inside the pack (for example
/// `"fonts/dogica.uf"`). Returns `Error(Undefined)` when the resource is
/// missing (`undefined` from AtomVM).
///
/// See [`atomvm:read_priv/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#read-priv-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "read_priv")
pub fn read_priv(pack: String, path: String) -> Result(BitArray, Error)

/// Read a `priv/` resource, returning `None` when absent instead of an error.
pub fn read_priv_option(pack: String, path: String) -> Option(BitArray) {
  case read_priv(pack, path) {
    Ok(bytes) -> option.Some(bytes)
    Error(_) -> option.None
  }
}

/// Random 32-bit integer.
///
/// For random byte sequences, prefer `crypto:strong_rand_bytes/1` rather than
/// the deprecated AtomVM `rand_bytes/1` API.
///
/// See [`atomvm:random/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#random-0).
@external(erlang, "atomvm", "random")
pub fn random() -> Int

/// Clock identifier for [`posix_clock_settime`](#posix_clock_settime).
pub type ClockId {
  Realtime
}

/// Set the system clock (platforms with `clock_settime(2)`).
///
/// `value_since_unix_epoch` is `#(seconds, nanoseconds)`.
///
/// See [`atomvm:posix_clock_settime/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-clock-settime-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_clock_settime")
pub fn posix_clock_settime(
  clock_id: ClockId,
  value_since_unix_epoch: #(Int, Int),
) -> Result(Nil, Error)

/// Opaque POSIX file descriptor (`atomvm:posix_fd()`).
///
/// Closed automatically when garbage-collected; prefer
/// [`posix_close`](#posix_close) when done.
pub type PosixFd

/// Opaque POSIX directory handle (`atomvm:posix_dir()`).
pub type PosixDir

/// Flags for [`posix_open`](#posix_open) / [`posix_open_mode`](#posix_open_mode).
///
/// Encode as Erlang atoms matching `atomvm:posix_open_flag()`.
///
/// See [`atomvm:posix_open/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-open-2).
pub type PosixOpenFlag {
  OExec
  ORdonly
  ORdwr
  OSearch
  OWronly
  OAppend
  OCloexec
  OCreat
  ODirectory
  ODsync
  OExcl
  ONoctty
  ONofollow
  ORsync
  OSync
  OTrunc
  OTtyAtom
}

/// Seek reference point for [`posix_seek`](#posix_seek).
pub type PosixWhence {
  SeekSet
  SeekCur
  SeekEnd
}

/// File status from [`posix_stat`](#posix_stat) / [`posix_fstat`](#posix_fstat).
pub type PosixStatInfo {
  PosixStatInfo(
    st_dev: Int,
    st_ino: Int,
    st_mode: Int,
    st_nlink: Int,
    st_uid: Int,
    st_gid: Int,
    st_size: Int,
    st_atime_s: Int,
    st_mtime_s: Int,
    st_ctime_s: Int,
  )
}

/// Directory entry from [`posix_readdir`](#posix_readdir).
pub type PosixDirent {
  PosixDirent(inode: Int, name: BitArray)
}

/// Subprocess option for [`subprocess`](#subprocess). Currently only `Stdout`.
pub type SubprocessOption {
  Stdout
}

/// Open a file with `open(3)` flags (non-blocking by default).
///
/// Platform-dependent: typically `generic_unix` / MCU builds with POSIX NIFs.
///
/// See [`atomvm:posix_open/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-open-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_open")
pub fn posix_open(
  path: String,
  flags: List(PosixOpenFlag),
) -> Result(PosixFd, Error)

/// Open a file, specifying creation `mode` bits.
///
/// See [`atomvm:posix_open/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-open-3).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_open_mode")
pub fn posix_open_mode(
  path: String,
  flags: List(PosixOpenFlag),
  mode: Int,
) -> Result(PosixFd, Error)

/// Close a file opened with [`posix_open`](#posix_open).
///
/// See [`atomvm:posix_close/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-close-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_close")
pub fn posix_close(file: PosixFd) -> Result(Nil, Error)

/// Read at most `count` bytes. `Ok(None)` means end-of-file.
///
/// See [`atomvm:posix_read/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-read-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_read")
pub fn posix_read(file: PosixFd, count: Int) -> Result(Option(BitArray), Error)

/// Write `data` to an open file. Returns bytes written.
///
/// See [`atomvm:posix_write/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-write-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_write")
pub fn posix_write(file: PosixFd, data: BitArray) -> Result(Int, Error)

/// Subscribe `pid` to read-readiness on `file`.
///
/// When readable, `{select, File, Ref, ready_input}` is sent. `ref` of `None`
/// passes `undefined` upstream.
///
/// See [`atomvm:posix_select_read/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-select-read-3).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_select_read")
pub fn posix_select_read(
  file: PosixFd,
  pid: Pid,
  ref: Option(Reference),
) -> Result(Nil, Error)

/// Subscribe `pid` to write-readiness on `file`.
///
/// See [`atomvm:posix_select_write/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-select-write-3).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_select_write")
pub fn posix_select_write(
  file: PosixFd,
  pid: Pid,
  ref: Option(Reference),
) -> Result(Nil, Error)

/// Cancel a prior select subscription on `file`.
///
/// See [`atomvm:posix_select_stop/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-select-stop-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_select_stop")
pub fn posix_select_stop(file: PosixFd) -> Result(Nil, Error)

/// Reposition the file cursor (`lseek(2)`). Returns the absolute offset.
///
/// See [`atomvm:posix_seek/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-seek-3).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_seek")
pub fn posix_seek(
  file: PosixFd,
  offset: Int,
  whence: PosixWhence,
) -> Result(Int, Error)

/// Read at most `count` bytes at `offset` without moving the cursor.
///
/// `Ok(None)` means end-of-file.
///
/// See [`atomvm:posix_pread/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-pread-3).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_pread")
pub fn posix_pread(
  file: PosixFd,
  count: Int,
  offset: Int,
) -> Result(Option(BitArray), Error)

/// Write `data` at `offset` without moving the cursor. Returns bytes written.
///
/// See [`atomvm:posix_pwrite/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-pwrite-3).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_pwrite")
pub fn posix_pwrite(
  file: PosixFd,
  data: BitArray,
  offset: Int,
) -> Result(Int, Error)

/// Flush file data to storage (`fsync(2)`).
///
/// See [`atomvm:posix_fsync/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-fsync-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_fsync")
pub fn posix_fsync(file: PosixFd) -> Result(Nil, Error)

/// Truncate an open file to `length` bytes (`ftruncate(2)`).
///
/// See [`atomvm:posix_ftruncate/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-ftruncate-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_ftruncate")
pub fn posix_ftruncate(file: PosixFd, length: Int) -> Result(Nil, Error)

/// Create a FIFO special file (`mkfifo(2)`).
///
/// See [`atomvm:posix_mkfifo/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-mkfifo-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_mkfifo")
pub fn posix_mkfifo(path: String, mode: Int) -> Result(Nil, Error)

/// Create a directory (`mkdir(2)`).
///
/// See [`atomvm:posix_mkdir/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-mkdir-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_mkdir")
pub fn posix_mkdir(path: String, mode: Int) -> Result(Nil, Error)

/// Remove a file (`unlink(2)`).
///
/// See [`atomvm:posix_unlink/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-unlink-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_unlink")
pub fn posix_unlink(path: String) -> Result(Nil, Error)

/// Remove an empty directory (`rmdir(2)`).
///
/// See [`atomvm:posix_rmdir/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-rmdir-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_rmdir")
pub fn posix_rmdir(path: String) -> Result(Nil, Error)

/// Rename a file or directory (`rename(2)`).
///
/// See [`atomvm:posix_rename/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-rename-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_rename")
pub fn posix_rename(old_path: String, new_path: String) -> Result(Nil, Error)

/// File status for `path` (`stat(2)`).
///
/// See [`atomvm:posix_stat/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-stat-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_stat")
pub fn posix_stat(path: String) -> Result(PosixStatInfo, Error)

/// File status for an open descriptor (`fstat(2)`).
///
/// See [`atomvm:posix_fstat/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-fstat-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_fstat")
pub fn posix_fstat(file: PosixFd) -> Result(PosixStatInfo, Error)

/// Open a directory (`opendir(3)`).
///
/// See [`atomvm:posix_opendir/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-opendir-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_opendir")
pub fn posix_opendir(path: String) -> Result(PosixDir, Error)

/// Close a directory opened with [`posix_opendir`](#posix_opendir).
///
/// See [`atomvm:posix_closedir/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-closedir-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_closedir")
pub fn posix_closedir(dir: PosixDir) -> Result(Nil, Error)

/// Read the next directory entry. `Ok(None)` means end-of-directory.
///
/// See [`atomvm:posix_readdir/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-readdir-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_readdir")
pub fn posix_readdir(dir: PosixDir) -> Result(Option(PosixDirent), Error)

/// Fork and execute a program, piping stdout for [`posix_read`](#posix_read).
///
/// Returns `#(os_pid, stdout_fd)`. `env` of `None` uses the VM environment.
/// `options` should include [`Stdout`](#SubprocessOption).
///
/// Platform-dependent (typically `generic_unix`).
///
/// See [`atomvm:subprocess/4`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#subprocess-4).
@external(erlang, "atomvm_gleam_atomvm_ffi", "subprocess")
pub fn subprocess(
  path: String,
  args: List(String),
  env: Option(List(String)),
  options: List(SubprocessOption),
) -> Result(#(Int, PosixFd), Error)

/// Send signal `signal` to OS process `os_pid` (`kill(2)`).
///
/// Typically used to terminate a process from [`subprocess`](#subprocess).
/// AtomVM 0.7 beta API.
///
/// See [`atomvm:posix_kill/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-kill-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_kill")
pub fn posix_kill(os_pid: Int, signal: Int) -> Result(Nil, Error)

/// When [`posix_tcsetattr`](#posix_tcsetattr) applies changes.
///
/// See [`atomvm:posix_tcsetattr/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-tcsetattr-3).
pub type TcsetattrWhen {
  Tcsanow
  Tcsadrain
  Tcsaflush
}

/// Queue selector for [`posix_tcflush`](#posix_tcflush).
///
/// See [`atomvm:posix_tcflush/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-tcflush-2).
pub type TcflushQueue {
  Tciflush
  Tcoflush
  Tcioflush
}

/// Serial parity for [`PosixTermios`](#PosixTermios) setattr options.
pub type TermiosParity {
  NoParity
  Even
  Odd
}

/// Serial flow control for [`PosixTermios`](#PosixTermios) setattr options.
pub type TermiosFlowControl {
  NoFlow
  Hardware
  Software
}

/// Terminal attributes (`atomvm:posix_termios()`).
///
/// [`posix_tcgetattr`](#posix_tcgetattr) fills the integer flag and speed
/// fields. For [`posix_tcsetattr`](#posix_tcsetattr), only `Some` keys are
/// applied (partial maps). Serial line options (`data_bits`, `stop_bits`,
/// `parity`, `flow_control`, `clocal`, `raw`) are setattr helpers.
///
/// Platform-dependent: typically `generic_unix` / UART POSIX builds.
///
/// See [posix_termios()](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#type-posix_termios).
pub type PosixTermios {
  PosixTermios(
    cflag: Option(Int),
    iflag: Option(Int),
    oflag: Option(Int),
    lflag: Option(Int),
    ispeed: Option(Int),
    ospeed: Option(Int),
    raw: Option(Bool),
    data_bits: Option(Int),
    stop_bits: Option(Int),
    parity: Option(TermiosParity),
    flow_control: Option(TermiosFlowControl),
    clocal: Option(Bool),
  )
}

/// Empty termios map (no keys applied by setattr).
pub fn empty_termios() -> PosixTermios {
  PosixTermios(
    cflag: option.None,
    iflag: option.None,
    oflag: option.None,
    lflag: option.None,
    ispeed: option.None,
    ospeed: option.None,
    raw: option.None,
    data_bits: option.None,
    stop_bits: option.None,
    parity: option.None,
    flow_control: option.None,
    clocal: option.None,
  )
}

/// Get terminal parameters (`tcgetattr(3)`).
///
/// Platform-dependent: typically `generic_unix` / UART POSIX builds.
///
/// See [`atomvm:posix_tcgetattr/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-tcgetattr-1).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_tcgetattr")
pub fn posix_tcgetattr(file: PosixFd) -> Result(PosixTermios, Error)

/// Set terminal parameters (`tcsetattr(3)`).
///
/// Only keys present as `Some` in `termios` are applied. Use
/// [`empty_termios`](#empty_termios) and set the fields you need.
///
/// Platform-dependent: typically `generic_unix` / UART POSIX builds.
///
/// See [`atomvm:posix_tcsetattr/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-tcsetattr-3).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_tcsetattr")
pub fn posix_tcsetattr(
  file: PosixFd,
  apply_when: TcsetattrWhen,
  termios: PosixTermios,
) -> Result(Nil, Error)

/// Discard terminal data (`tcflush(3)`).
///
/// Platform-dependent: typically `generic_unix` / UART POSIX builds.
///
/// See [`atomvm:posix_tcflush/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/eavmlib/atomvm.html#posix-tcflush-2).
@external(erlang, "atomvm_gleam_atomvm_ffi", "posix_tcflush")
pub fn posix_tcflush(
  file: PosixFd,
  queue_selector: TcflushQueue,
) -> Result(Nil, Error)

/// Return the node creation value used in references and pids.
///
/// Exported on AtomVM 0.7 (`get_creation/0`); marked hidden in upstream edoc.
///
/// See [`atomvm:get_creation/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/eavmlib/src/atomvm.erl#L646).
@external(erlang, "atomvm", "get_creation")
pub fn get_creation() -> Int
