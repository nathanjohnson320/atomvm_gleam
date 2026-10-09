import atomvm_gleam/console
import atomvm_gleam/crypto
import atomvm_gleam/emscripten
import gleam/erlang/atom

@external(erlang, "atomvm_gleam_crypto_ffi", "map_raised")
fn crypto_map_raised(reason: atom.Atom) -> Result(BitArray, crypto.Error)

@external(erlang, "atomvm_gleam_console_ffi", "map_raised")
fn console_map_raised(reason: atom.Atom) -> Result(Nil, console.Error)

@external(erlang, "atomvm_gleam_emscripten_ffi", "map_raised")
fn emscripten_map_raised(reason: atom.Atom) -> Result(Nil, emscripten.Error)

pub fn crypto_undef_is_other_not_not_supported_test() {
  assert crypto_map_raised(atom.create("undef")) == Error(crypto.Other("undef"))
}

pub fn crypto_undefined_nif_stub_is_other_test() {
  assert crypto_map_raised(atom.create("undefined"))
    == Error(crypto.Other("undefined"))
}

pub fn crypto_not_supported_passthrough_test() {
  assert crypto_map_raised(atom.create("not_supported"))
    == Error(crypto.NotSupported)
}

pub fn crypto_badarg_passthrough_test() {
  assert crypto_map_raised(atom.create("badarg")) == Error(crypto.Badarg)
}

pub fn console_undef_is_other_not_not_supported_test() {
  assert console_map_raised(atom.create("undef"))
    == Error(console.Other("undef"))
}

pub fn console_undefined_nif_stub_is_other_test() {
  assert console_map_raised(atom.create("undefined"))
    == Error(console.Other("undefined"))
}

pub fn console_not_supported_passthrough_test() {
  assert console_map_raised(atom.create("not_supported"))
    == Error(console.NotSupported)
}

pub fn emscripten_undef_is_not_supported_test() {
  assert emscripten_map_raised(atom.create("undef"))
    == Error(emscripten.NotSupported)
}

pub fn emscripten_undefined_nif_stub_is_failed_test() {
  assert emscripten_map_raised(atom.create("undefined"))
    == Error(emscripten.Failed)
}

pub fn emscripten_not_supported_passthrough_test() {
  assert emscripten_map_raised(atom.create("not_supported"))
    == Error(emscripten.NotSupported)
}
