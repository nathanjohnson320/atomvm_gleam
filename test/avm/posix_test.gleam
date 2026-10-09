//// POSIX file helpers — GenericUnix only.

import atomvm_gleam/atomvm
import avm/check.{type Failure}
import gleam/option
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  use _ <- result.try(mkdir_roundtrip())
  use _ <- result.try(file_roundtrip())
  use _ <- result.try(stat_opendir())
  use _ <- result.try(termios_empty())
  use _ <- result.try(creation_smoke())
  Ok(Nil)
}

fn mkdir_roundtrip() -> Result(Nil, Failure) {
  let dir = "/tmp/atomvm_gleam_posix_test"
  let _ = atomvm.posix_rmdir(dir)
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_mkdir",
    atomvm.posix_mkdir(dir, 0o755),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_rmdir",
    atomvm.posix_rmdir(dir),
  ))
  Ok(Nil)
}

fn file_roundtrip() -> Result(Nil, Failure) {
  let path = "/tmp/atomvm_gleam_posix_file.bin"
  let path2 = "/tmp/atomvm_gleam_posix_file2.bin"
  let _ = atomvm.posix_unlink(path)
  let _ = atomvm.posix_unlink(path2)
  use fd <- result.try(check.cover_ok(
    "atomvm.posix_open_mode",
    atomvm.posix_open_mode(
      path,
      [atomvm.OCreat, atomvm.OWronly, atomvm.OTrunc],
      0o644,
    ),
  ))
  use written <- result.try(check.cover_ok(
    "atomvm.posix_write",
    atomvm.posix_write(fd, <<"hello">>),
  ))
  use _ <- result.try(check.assert_eq("bytes written", written, 5))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_fsync",
    atomvm.posix_fsync(fd),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_ftruncate",
    atomvm.posix_ftruncate(fd, 5),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_fstat",
    atomvm.posix_fstat(fd),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_close",
    atomvm.posix_close(fd),
  ))
  use fd2 <- result.try(check.cover_ok(
    "atomvm.posix_open",
    atomvm.posix_open(path, [atomvm.ORdonly]),
  ))
  use maybe_data <- result.try(check.cover_ok(
    "atomvm.posix_read",
    atomvm.posix_read(fd2, 16),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_seek",
    atomvm.posix_seek(fd2, 0, atomvm.SeekSet),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_pread",
    atomvm.posix_pread(fd2, 5, 0),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_close",
    atomvm.posix_close(fd2),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_stat",
    atomvm.posix_stat(path),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_rename",
    atomvm.posix_rename(path, path2),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_unlink",
    atomvm.posix_unlink(path2),
  ))
  case maybe_data {
    option.Some(data) -> check.assert_eq("file contents", data, <<"hello">>)
    option.None -> check.fail("posix_read returned None")
  }
}

fn stat_opendir() -> Result(Nil, Failure) {
  let dir = "/tmp"
  use d <- result.try(check.cover_ok(
    "atomvm.posix_opendir",
    atomvm.posix_opendir(dir),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_readdir",
    atomvm.posix_readdir(d),
  ))
  use _ <- result.try(check.cover_ok(
    "atomvm.posix_closedir",
    atomvm.posix_closedir(d),
  ))
  Ok(Nil)
}

fn termios_empty() -> Result(Nil, Failure) {
  let _ = atomvm.empty_termios()
  check.cover("atomvm.empty_termios", check.ok())
}

fn creation_smoke() -> Result(Nil, Failure) {
  let _ = atomvm.get_creation()
  check.cover("atomvm.get_creation", check.ok())
}
