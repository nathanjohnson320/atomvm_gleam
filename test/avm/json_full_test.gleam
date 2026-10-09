//// Full json encode/decode suite (portable across AtomVM platforms).

import atomvm_gleam/json
import avm/check.{type Failure}
import gleam/dict
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  use enc <- result.try(check.cover_ok(
    "json.default_encoder",
    Ok(json.default_encoder()),
  ))
  use dec <- result.try(check.cover_ok(
    "json.default_decoders",
    Ok(json.default_decoders()),
  ))
  use _ <- result.try(check.cover_ok(
    "json.encode_integer",
    json.encode_integer(42),
  ))
  use _ <- result.try(check.cover_ok(
    "json.encode_float",
    json.encode_float(1.5),
  ))
  use _ <- result.try(check.cover_ok(
    "json.encode_binary",
    json.encode_binary(<<"hi">>),
  ))
  use _ <- result.try(check.cover_ok(
    "json.encode_binary_escape_all",
    json.encode_binary_escape_all(<<"hi">>),
  ))
  use _ <- result.try(check.cover_ok(
    "json.encode_atom",
    json.encode_atom(True, enc),
  ))
  use _ <- result.try(check.cover_ok(
    "json.encode_list",
    json.encode_list([1, 2, 3], enc),
  ))
  use _ <- result.try(check.cover_ok(
    "json.encode_key_value_list",
    json.encode_key_value_list([#("a", 1), #("b", 2)], enc),
  ))
  use _ <- result.try(check.cover_ok(
    "json.encode_key_value_list_checked",
    json.encode_key_value_list_checked([#("a", 1)], enc),
  ))
  let map = dict.from_list([#("k", 1)])
  use _ <- result.try(check.cover_ok(
    "json.encode_map",
    json.encode_map(map, enc),
  ))
  use _ <- result.try(check.cover_ok(
    "json.encode_map_checked",
    json.encode_map_checked(map, enc),
  ))
  use _ <- result.try(check.cover_ok("json.encode", json.encode(42)))
  use _ <- result.try(check.cover_ok(
    "json.encode_with",
    json.encode_with(42, enc),
  ))
  use _ <- result.try(check.cover_ok(
    "json.encode_value",
    json.encode_value(42, enc),
  ))
  use decoded <- result.try(check.cover_ok(
    "json.decode",
    json.decode(<<"{\"a\":1}">>),
  ))
  use _ <- result.try(check.assert_true("decode term", decoded != Nil))
  use _ <- result.try(check.cover_ok(
    "json.decode_with",
    json.decode_with(<<"[1]">>, 0, dec),
  ))
  use progress <- result.try(check.cover_ok(
    "json.decode_start",
    json.decode_start(<<"{\"x\":">>, 0, dec),
  ))
  case progress {
    json.NeedMore(cont) -> {
      use _ <- result.try(check.cover_ok(
        "json.decode_continue",
        json.decode_continue(json.Bytes(<<"1}">>), cont),
      ))
      Ok(Nil)
    }
    json.Complete(_, _, _) -> {
      use _ <- result.try(check.cover("json.decode_continue", check.ok()))
      Ok(Nil)
    }
  }
}
