//// Ok-or-NotSupported helpers for platform-owned APIs.

import avm/check.{type Failure}
import gleam/result

pub fn ok_or_not_supported(
  id: String,
  result: Result(a, e),
  is_not_supported: fn(e) -> Bool,
  format: fn(e) -> String,
) -> Result(Nil, Failure) {
  case result {
    Ok(_) -> {
      use _ <- result.try(check.cover(id, check.ok()))
      Ok(Nil)
    }
    Error(reason) ->
      case is_not_supported(reason) {
        True -> check.cover_not_supported(id)
        False -> check.fail(id <> ": " <> format(reason))
      }
  }
}

/// True when an Error string is a missing-module stub (`undef` / `undefined`).
pub fn is_undef_reason(reason: String) -> Bool {
  reason == "undef" || reason == "undefined"
}

pub fn ok_value_or_not_supported(
  id: String,
  result: Result(a, e),
  is_not_supported: fn(e) -> Bool,
  format: fn(e) -> String,
) -> Result(Result(a, Nil), Failure) {
  case result {
    Ok(value) -> {
      use _ <- result.try(check.cover(id, check.ok()))
      Ok(Ok(value))
    }
    Error(reason) ->
      case is_not_supported(reason) {
        True -> {
          use _ <- result.try(check.cover_not_supported(id))
          Ok(Error(Nil))
        }
        False -> {
          use _ <- result.try(check.fail(id <> ": " <> format(reason)))
          Ok(Error(Nil))
        }
      }
  }
}
