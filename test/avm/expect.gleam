//// Platform-aware Result helpers for the AtomVM harness.
////
//// - Owning platform, API must work → [`must_ok`](#must_ok) / [`must_ok_value`](#must_ok_value)
//// - Owning platform, call may fail for HW/QEMU reasons → [`ok_or_runtime`](#ok_or_runtime)
////   (`NotSupported` / undef must still fail - missing module is never “fine”)
//// - Off-platform → [`must_not_supported`](#must_not_supported)
//// - Harness unavailable → `integration.skip` (no cover tag)

import avm/check.{type Failure}
import gleam/result

/// Owning platform: `Ok` required.
pub fn must_ok(
  id: String,
  outcome: Result(a, e),
  format: fn(e) -> String,
) -> Result(Nil, Failure) {
  case outcome {
    Ok(_) -> check.cover(id, check.ok())
    Error(reason) -> check.fail(id <> ": " <> format(reason))
  }
}

/// Owning platform: `Ok(value)` required; returns the value.
pub fn must_ok_value(
  id: String,
  outcome: Result(a, e),
  format: fn(e) -> String,
) -> Result(a, Failure) {
  case outcome {
    Ok(value) -> {
      use _ <- result.try(check.cover(id, check.ok()))
      Ok(value)
    }
    Error(reason) -> Error(check.Failure(id <> ": " <> format(reason)))
  }
}

/// Owning platform: `Ok` preferred; `is_runtime` errors are tolerated
/// (HW missing, QEMU limit, no peer). `NotSupported` / undef must not be
/// classified as runtime - those mean the module is absent on a platform
/// that should own it.
pub fn ok_or_runtime(
  id: String,
  outcome: Result(a, e),
  is_runtime: fn(e) -> Bool,
  format: fn(e) -> String,
) -> Result(Nil, Failure) {
  case outcome {
    Ok(_) -> check.cover(id, check.ok())
    Error(reason) ->
      case is_runtime(reason) {
        True -> check.cover(id, check.ok())
        False -> check.fail(id <> ": " <> format(reason))
      }
  }
}

/// Like [`ok_or_runtime`](#ok_or_runtime) but returns `Ok(Some(value))` /
/// `Ok(None)` when the runtime failure is tolerated.
pub fn ok_value_or_runtime(
  id: String,
  outcome: Result(a, e),
  is_runtime: fn(e) -> Bool,
  format: fn(e) -> String,
) -> Result(Result(a, Nil), Failure) {
  case outcome {
    Ok(value) -> {
      use _ <- result.try(check.cover(id, check.ok()))
      Ok(Ok(value))
    }
    Error(reason) ->
      case is_runtime(reason) {
        True -> {
          use _ <- result.try(check.cover(id, check.ok()))
          Ok(Error(Nil))
        }
        False -> Error(check.Failure(id <> ": " <> format(reason)))
      }
  }
}

/// Off-platform: Error must be NotSupported-shaped (`is_not_supported`).
pub fn must_not_supported(
  id: String,
  outcome: Result(a, e),
  is_not_supported: fn(e) -> Bool,
  format: fn(e) -> String,
) -> Result(Nil, Failure) {
  case outcome {
    Ok(_) -> check.fail(id <> ": expected NotSupported, got Ok")
    Error(reason) ->
      case is_not_supported(reason) {
        True -> check.cover_not_supported(id)
        False ->
          check.fail(id <> ": expected NotSupported, got " <> format(reason))
      }
  }
}

/// True when an Error string is a missing-module stub (`undef` / `undefined`).
pub fn is_undef_reason(reason: String) -> Bool {
  reason == "undef" || reason == "undefined"
}
