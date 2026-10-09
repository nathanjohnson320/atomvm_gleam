//// Crypto suite: Ok on WASM; Ok / NotSupported / undef elsewhere.

import atomvm_gleam/atomvm
import atomvm_gleam/crypto
import avm/check.{type Failure}
import gleam/bit_array
import gleam/option
import gleam/result

pub fn run() -> Result(Nil, Failure) {
  use available <- result.try(probe_available())
  case available {
    False -> skip_all_remaining()
    True -> {
      use _ <- result.try(hash_family())
      use _ <- result.try(mac_family())
      use _ <- result.try(rand_and_equals())
      use _ <- result.try(one_time_ciphers())
      use _ <- result.try(streaming_cipher())
      use _ <- result.try(aead_roundtrip())
      use _ <- result.try(pbkdf2_smoke())
      use _ <- result.try(ec_family())
      use _ <- result.try(eddsa_optional())
      use _ <- result.try(info_lib_smoke())
      Ok(Nil)
    }
  }
}

fn probe_available() -> Result(Bool, Failure) {
  case crypto.hash(crypto.Sha256, <<"probe">>) {
    Ok(_) -> {
      use _ <- result.try(check.cover("crypto.hash", check.ok()))
      Ok(True)
    }
    Error(crypto.NotSupported) | Error(crypto.Other("undef")) -> {
      use _ <- result.try(missing_tag("crypto.hash"))
      Ok(False)
    }
    Error(other) ->
      Error(check.Failure("crypto.hash: " <> crypto.error_to_string(other)))
  }
}

fn missing_tag(id: String) -> Result(Nil, Failure) {
  // AtomVM WASM may expose hash but omit cipher/EC NIFs; treat as NotSupported.
  let _ = atomvm.platform()
  check.cover_not_supported(id)
}

fn skip_all_remaining() -> Result(Nil, Failure) {
  let ids = [
    "crypto.hash_init", "crypto.hash_update", "crypto.hash_final",
    "crypto.mac_hmac", "crypto.mac_hmac_ripemd160", "crypto.mac_cmac",
    "crypto.mac_init_hmac", "crypto.mac_init_hmac_ripemd160",
    "crypto.mac_init_cmac", "crypto.mac_update", "crypto.mac_final",
    "crypto.mac_final_n", "crypto.strong_rand_bytes", "crypto.hash_equals",
    "crypto.crypto_one_time", "crypto.crypto_one_time_iv", "crypto.crypto_init",
    "crypto.crypto_init_iv", "crypto.crypto_update", "crypto.crypto_final",
    "crypto.crypto_one_time_aead_encrypt",
    "crypto.crypto_one_time_aead_encrypt_tag_length",
    "crypto.crypto_one_time_aead_decrypt", "crypto.pbkdf2_hmac",
    "crypto.generate_key_ecdh", "crypto.compute_key_ecdh", "crypto.sign_ecdsa",
    "crypto.verify_ecdsa", "crypto.generate_key_eddh", "crypto.compute_key_eddh",
    "crypto.generate_key_eddsa", "crypto.sign_eddsa", "crypto.verify_eddsa",
    "crypto.info_lib",
  ]
  skip_ids(ids)
}

fn skip_ids(ids: List(String)) -> Result(Nil, Failure) {
  case ids {
    [] -> Ok(Nil)
    [id, ..rest] -> {
      use _ <- result.try(missing_tag(id))
      skip_ids(rest)
    }
  }
}

fn take(
  id: String,
  result: Result(a, crypto.Error),
) -> Result(option.Option(a), Failure) {
  case result {
    Ok(value) -> {
      use _ <- result.try(check.cover(id, check.ok()))
      Ok(option.Some(value))
    }
    Error(crypto.NotSupported) | Error(crypto.Other("undef")) -> {
      use _ <- result.try(missing_tag(id))
      Ok(option.None)
    }
    // Optional algorithms (CMAC / libsodium) may return Failed when absent.
    Error(crypto.Failed) -> {
      use _ <- result.try(check.cover_not_supported(id))
      Ok(option.None)
    }
    Error(other) ->
      Error(check.Failure(id <> ": " <> crypto.error_to_string(other)))
  }
}

fn must(id: String, result: Result(a, crypto.Error)) -> Result(a, Failure) {
  use maybe <- result.try(take(id, result))
  case maybe {
    option.Some(value) -> Ok(value)
    option.None -> Error(check.Failure(id <> ": expected Ok"))
  }
}

fn hash_family() -> Result(Nil, Failure) {
  // crypto.hash already tagged in probe; re-hash for streaming setup.
  use digest <- result.try(must(
    "crypto.hash",
    crypto.hash(crypto.Sha256, <<"atomvm_gleam">>),
  ))
  use _ <- result.try(check.assert_eq(
    "sha256 size",
    bit_array.byte_size(digest),
    32,
  ))
  // Some builds (e.g. Pico) expose hash/1 but omit streaming hash NIFs.
  use maybe_st <- result.try(take(
    "crypto.hash_init",
    crypto.hash_init(crypto.Sha256),
  ))
  case maybe_st {
    option.None -> {
      use _ <- result.try(check.cover_not_supported("crypto.hash_update"))
      use _ <- result.try(check.cover_not_supported("crypto.hash_final"))
      Ok(Nil)
    }
    option.Some(st) -> {
      use st2 <- result.try(must(
        "crypto.hash_update",
        crypto.hash_update(st, <<"ab">>),
      ))
      use digest2 <- result.try(must(
        "crypto.hash_final",
        crypto.hash_final(st2),
      ))
      check.assert_eq("stream hash size", bit_array.byte_size(digest2), 32)
    }
  }
}

fn mac_family() -> Result(Nil, Failure) {
  let key = <<"secret-key!!!!!!!!">>
  let data = <<"payload">>
  // Pico may expose hash/1 without HMAC NIFs.
  use maybe_mac <- result.try(take(
    "crypto.mac_hmac",
    crypto.mac_hmac(crypto.Sha256, key, data),
  ))
  case maybe_mac {
    option.None -> {
      use _ <- result.try(check.cover_not_supported("crypto.mac_hmac_ripemd160"))
      use _ <- result.try(check.cover_not_supported("crypto.mac_cmac"))
      use _ <- result.try(check.cover_not_supported("crypto.mac_init_hmac"))
      use _ <- result.try(check.cover_not_supported(
        "crypto.mac_init_hmac_ripemd160",
      ))
      use _ <- result.try(check.cover_not_supported("crypto.mac_init_cmac"))
      use _ <- result.try(check.cover_not_supported("crypto.mac_update"))
      use _ <- result.try(check.cover_not_supported("crypto.mac_final"))
      use _ <- result.try(check.cover_not_supported("crypto.mac_final_n"))
      Ok(Nil)
    }
    option.Some(mac) -> {
      use _ <- result.try(check.assert_true(
        "hmac nonempty",
        bit_array.byte_size(mac) > 0,
      ))
      use _ <- result.try(take(
        "crypto.mac_hmac_ripemd160",
        crypto.mac_hmac_ripemd160(key, data),
      ))
      use _ <- result.try(take(
        "crypto.mac_cmac",
        crypto.mac_cmac(crypto.CmacAes128Ecb, key, data),
      ))
      use st <- result.try(must(
        "crypto.mac_init_hmac",
        crypto.mac_init_hmac(crypto.Sha256, key),
      ))
      use st2 <- result.try(must(
        "crypto.mac_update",
        crypto.mac_update(st, data),
      ))
      use mac2 <- result.try(must("crypto.mac_final", crypto.mac_final(st2)))
      use _ <- result.try(check.assert_true(
        "mac_final nonempty",
        bit_array.byte_size(mac2) > 0,
      ))
      use st3 <- result.try(must(
        "crypto.mac_init_hmac",
        crypto.mac_init_hmac(crypto.Sha256, key),
      ))
      use st4 <- result.try(check.assert_ok(
        "mac_update 2",
        crypto.mac_update(st3, data),
      ))
      use trunc <- result.try(must(
        "crypto.mac_final_n",
        crypto.mac_final_n(st4, 8),
      ))
      use _ <- result.try(check.assert_eq(
        "mac_final_n size",
        bit_array.byte_size(trunc),
        8,
      ))
      use _ <- result.try(take(
        "crypto.mac_init_hmac_ripemd160",
        crypto.mac_init_hmac_ripemd160(key),
      ))
      use _ <- result.try(take(
        "crypto.mac_init_cmac",
        crypto.mac_init_cmac(crypto.CmacAes128Ecb, key),
      ))
      Ok(Nil)
    }
  }
}

fn rand_and_equals() -> Result(Nil, Failure) {
  use bytes <- result.try(must(
    "crypto.strong_rand_bytes",
    crypto.strong_rand_bytes(16),
  ))
  use _ <- result.try(check.assert_eq(
    "rand size",
    bit_array.byte_size(bytes),
    16,
  ))
  use eq <- result.try(must(
    "crypto.hash_equals",
    crypto.hash_equals(bytes, bytes),
  ))
  check.assert_true("hash_equals self", eq)
}

fn one_time_ciphers() -> Result(Nil, Failure) {
  let key16 = <<"0123456789abcdef">>
  let iv = <<"0123456789abcdef">>
  let block = <<"0123456789abcdef">>
  use ct <- result.try(must(
    "crypto.crypto_one_time",
    crypto.crypto_one_time(
      crypto.Aes128Ecb,
      key16,
      block,
      crypto.encrypt_opts(),
    ),
  ))
  use pt <- result.try(check.assert_ok(
    "ecb decrypt",
    crypto.crypto_one_time(crypto.Aes128Ecb, key16, ct, crypto.decrypt_opts()),
  ))
  use _ <- result.try(check.assert_eq("ecb roundtrip", pt, block))
  use ct2 <- result.try(must(
    "crypto.crypto_one_time_iv",
    crypto.crypto_one_time_iv(
      crypto.Aes128Ctr,
      key16,
      iv,
      <<"hello crypto">>,
      crypto.encrypt_opts(),
    ),
  ))
  use pt2 <- result.try(check.assert_ok(
    "ctr decrypt",
    crypto.crypto_one_time_iv(
      crypto.Aes128Ctr,
      key16,
      iv,
      ct2,
      crypto.decrypt_opts(),
    ),
  ))
  check.assert_eq("ctr roundtrip", pt2, <<"hello crypto">>)
}

fn streaming_cipher() -> Result(Nil, Failure) {
  let key16 = <<"0123456789abcdef">>
  let block = <<"0123456789abcdef">>
  use maybe_st <- result.try(take(
    "crypto.crypto_init",
    crypto.crypto_init(crypto.Aes128Ecb, key16, crypto.encrypt_opts()),
  ))
  case maybe_st {
    option.None -> {
      use _ <- result.try(check.cover_not_supported("crypto.crypto_update"))
      use _ <- result.try(check.cover_not_supported("crypto.crypto_final"))
      use _ <- result.try(check.cover_not_supported("crypto.crypto_init_iv"))
      Ok(Nil)
    }
    option.Some(st) -> {
      use out <- result.try(must(
        "crypto.crypto_update",
        crypto.crypto_update(st, block),
      ))
      use _ <- result.try(must("crypto.crypto_final", crypto.crypto_final(st)))
      use _ <- result.try(check.assert_true(
        "stream out",
        bit_array.byte_size(out) > 0,
      ))
      let iv = <<"0123456789abcdef">>
      use _ <- result.try(take(
        "crypto.crypto_init_iv",
        crypto.crypto_init_iv(
          crypto.Aes128Ctr,
          key16,
          iv,
          crypto.encrypt_opts(),
        ),
      ))
      Ok(Nil)
    }
  }
}

fn aead_roundtrip() -> Result(Nil, Failure) {
  let key16 = <<"0123456789abcdef">>
  let iv = <<"0123456789ab">>
  let pt = <<"aead plaintext">>
  let aad = <<"aad">>
  use pair <- result.try(take(
    "crypto.crypto_one_time_aead_encrypt",
    crypto.crypto_one_time_aead_encrypt(crypto.Aes128Gcm, key16, iv, pt, aad),
  ))
  case pair {
    option.None -> {
      use _ <- result.try(check.cover_not_supported(
        "crypto.crypto_one_time_aead_encrypt_tag_length",
      ))
      use _ <- result.try(check.cover_not_supported(
        "crypto.crypto_one_time_aead_decrypt",
      ))
      Ok(Nil)
    }
    option.Some(#(ct, tag)) -> {
      use _ <- result.try(take(
        "crypto.crypto_one_time_aead_encrypt_tag_length",
        crypto.crypto_one_time_aead_encrypt_tag_length(
          crypto.Aes128Gcm,
          key16,
          iv,
          pt,
          aad,
          16,
        ),
      ))
      use pt2 <- result.try(must(
        "crypto.crypto_one_time_aead_decrypt",
        crypto.crypto_one_time_aead_decrypt(
          crypto.Aes128Gcm,
          key16,
          iv,
          ct,
          aad,
          tag,
        ),
      ))
      check.assert_eq("aead roundtrip", pt2, pt)
    }
  }
}

fn pbkdf2_smoke() -> Result(Nil, Failure) {
  use key <- result.try(must(
    "crypto.pbkdf2_hmac",
    crypto.pbkdf2_hmac(crypto.Sha256, <<"pass">>, <<"salt">>, 10, 16),
  ))
  check.assert_eq("pbkdf2 len", bit_array.byte_size(key), 16)
}

fn ec_family() -> Result(Nil, Failure) {
  use pair_a <- result.try(take(
    "crypto.generate_key_ecdh",
    crypto.generate_key_ecdh(crypto.Secp256r1),
  ))
  case pair_a {
    option.None -> {
      use _ <- result.try(check.cover_not_supported("crypto.compute_key_ecdh"))
      use _ <- result.try(check.cover_not_supported("crypto.sign_ecdsa"))
      use _ <- result.try(check.cover_not_supported("crypto.verify_ecdsa"))
      use _ <- result.try(check.cover_not_supported("crypto.generate_key_eddh"))
      use _ <- result.try(check.cover_not_supported("crypto.compute_key_eddh"))
      Ok(Nil)
    }
    option.Some(#(public_a, priv_a)) -> {
      use #(public_b, priv_b) <- result.try(must(
        "crypto.generate_key_ecdh",
        crypto.generate_key_ecdh(crypto.Secp256r1),
      ))
      use secret_a <- result.try(must(
        "crypto.compute_key_ecdh",
        crypto.compute_key_ecdh(crypto.Secp256r1, public_b, priv_a),
      ))
      use secret_b <- result.try(check.assert_ok(
        "compute_key_ecdh b",
        crypto.compute_key_ecdh(crypto.Secp256r1, public_a, priv_b),
      ))
      use _ <- result.try(check.assert_eq("ecdh match", secret_a, secret_b))
      use sig <- result.try(must(
        "crypto.sign_ecdsa",
        crypto.sign_ecdsa(crypto.Sha256, <<"msg">>, priv_a, crypto.Secp256r1),
      ))
      use ok <- result.try(must(
        "crypto.verify_ecdsa",
        crypto.verify_ecdsa(
          crypto.Sha256,
          <<"msg">>,
          sig,
          public_a,
          crypto.Secp256r1,
        ),
      ))
      use _ <- result.try(check.assert_true("ecdsa verify", ok))
      use ed_a <- result.try(take(
        "crypto.generate_key_eddh",
        crypto.generate_key_eddh(),
      ))
      case ed_a {
        option.None -> check.cover_not_supported("crypto.compute_key_eddh")
        option.Some(#(public1, _priv1)) -> {
          use #(_public2, priv2) <- result.try(must(
            "crypto.generate_key_eddh",
            crypto.generate_key_eddh(),
          ))
          use _ <- result.try(must(
            "crypto.compute_key_eddh",
            crypto.compute_key_eddh(public1, priv2),
          ))
          Ok(Nil)
        }
      }
    }
  }
}

fn eddsa_optional() -> Result(Nil, Failure) {
  use pair <- result.try(take(
    "crypto.generate_key_eddsa",
    crypto.generate_key_eddsa(),
  ))
  case pair {
    option.None -> {
      use _ <- result.try(check.cover_not_supported("crypto.sign_eddsa"))
      use _ <- result.try(check.cover_not_supported("crypto.verify_eddsa"))
      Ok(Nil)
    }
    option.Some(#(public_key, priv)) -> {
      use sig <- result.try(must(
        "crypto.sign_eddsa",
        crypto.sign_eddsa(<<"hi">>, priv),
      ))
      use ok <- result.try(must(
        "crypto.verify_eddsa",
        crypto.verify_eddsa(<<"hi">>, sig, public_key),
      ))
      check.assert_true("eddsa verify", ok)
    }
  }
}

fn info_lib_smoke() -> Result(Nil, Failure) {
  use libs <- result.try(must("crypto.info_lib", crypto.info_lib()))
  check.assert_true("info_lib nonempty", libs != [])
}
