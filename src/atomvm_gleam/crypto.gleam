/// Typed Gleam wrappers for AtomVM 0.7 `:crypto` (estdlib).
///
/// Source: [`crypto.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/estdlib/src/crypto.erl#L1).
/// Docs: [Module crypto](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html).
///
/// **Availability:** many algorithms and APIs depend on the AtomVM build
/// (Mbed TLS always; libsodium optional for Ed25519 / ChaCha20-Poly1305 and
/// related helpers). Unsupported combinations typically raise `badarg` or
/// `not_supported` from the NIF layer.
///
/// **Wrapped:** `hash/2`, `hash_init/1`, `hash_update/2`, `hash_final/1`,
/// `mac/4`, `mac_init/3`, `mac_update/2`, `mac_final/1`, `mac_finalN/2`,
/// `strong_rand_bytes/1`, `crypto_one_time/4`, `crypto_one_time/5`,
/// `crypto_one_time_aead/6`, `crypto_one_time_aead/7`, streaming cipher
/// `crypto_init/3,4`, `crypto_update/2`, `crypto_final/1`, `pbkdf2_hmac/5`,
/// `generate_key/2`, `compute_key/4`, `sign/4`, `verify/5`, `hash_equals/2`,
/// `info_lib/0`.
///
/// **Streaming cipher notes:** state is mutable (unlike hash/MAC). After
/// `crypto_final`, the state must not be reused (`badarg`). `{padding,
/// pkcs_padding}` is supported only with CBC ciphers on AtomVM.
import gleam/option.{type Option}

/// Opaque streaming hash state (`hash_state()`).
pub type HashState

/// Opaque streaming MAC state (`mac_state()`).
pub type MacState

/// Opaque streaming cipher state (`crypto_state()`).
///
/// Unlike hash/MAC state, this handle is mutated in place by
/// [`crypto_update`](#crypto_update) and [`crypto_final`](#crypto_final).
pub type CipherState

/// Errors from `:crypto` NIFs and helpers.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  Other(String)
}

/// Hash algorithms for `hash`, streaming hash, HMAC, and PBKDF2.
pub type HashAlgorithm {
  Md5
  Sha
  Sha224
  Sha256
  Sha384
  Sha512
}

/// ECB ciphers for [`crypto_one_time`](#crypto_one_time) (no IV).
pub type CipherNoIv {
  Aes128Ecb
  Aes192Ecb
  Aes256Ecb
}

/// IV ciphers for [`crypto_one_time_iv`](#crypto_one_time_iv).
pub type CipherIv {
  Aes128Cbc
  Aes192Cbc
  Aes256Cbc
  Aes128Cfb128
  Aes192Cfb128
  Aes256Cfb128
  Aes128Ctr
  Aes192Ctr
  Aes256Ctr
  Aes128Ofb
  Aes192Ofb
  Aes256Ofb
}

/// AEAD ciphers for [`crypto_one_time_aead`](#crypto_one_time_aead_encrypt).
pub type CipherAead {
  Aes128Gcm
  Aes192Gcm
  Aes256Gcm
  Aes128Ccm
  Aes192Ccm
  Aes256Ccm
  Chacha20Poly1305
}

/// AES CBC/ECB subtypes for CMAC. Mapped to upstream cipher atoms in FFI.
pub type CmacCipher {
  CmacAes128Cbc
  CmacAes128Ecb
  CmacAes192Cbc
  CmacAes192Ecb
  CmacAes256Cbc
  CmacAes256Ecb
}

/// Padding for `crypto_one_time` option lists.
///
/// AtomVM supports `pkcs_padding` only with CBC ciphers (not ECB).
pub type Padding {
  NoPadding
  PkcsPadding
}

/// Encrypt/decrypt options for one-shot ciphers.
pub type CryptoOpts {
  CryptoOpts(encrypt: Bool, padding: Option(Padding))
}

/// Named curves for ECDH / ECDSA (plus `X25519` for ECDH/EDDH).
pub type EcCurve {
  Secp256k1
  Secp256r1
  Secp384r1
  Secp521r1
  BrainpoolP256r1
  BrainpoolP384r1
  BrainpoolP512r1
  X25519
}

/// Library entry from [`info_lib`](#info_lib).
pub type LibInfo {
  LibInfo(name: BitArray, version_num: Int, version_str: BitArray)
}

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    Other(reason) -> reason
  }
}

/// Default encrypt options (no explicit padding entry).
pub fn encrypt_opts() -> CryptoOpts {
  CryptoOpts(encrypt: True, padding: option.None)
}

/// Default decrypt options (no explicit padding entry).
pub fn decrypt_opts() -> CryptoOpts {
  CryptoOpts(encrypt: False, padding: option.None)
}

/// Hash `data` with `algorithm`.
///
/// See [`crypto:hash/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#hash-2).
pub fn hash(
  algorithm: HashAlgorithm,
  data: BitArray,
) -> Result(BitArray, Error) {
  hash_ffi(algorithm, data)
}

/// Start a streaming hash.
///
/// See [`crypto:hash_init/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#hash-init-1).
pub fn hash_init(algorithm: HashAlgorithm) -> Result(HashState, Error) {
  hash_init_ffi(algorithm)
}

/// Fold `data` into a streaming hash (returns a new state).
///
/// See [`crypto:hash_update/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#hash-update-2).
pub fn hash_update(
  state: HashState,
  data: BitArray,
) -> Result(HashState, Error) {
  hash_update_ffi(state, data)
}

/// Finalize a streaming hash and return the digest.
///
/// See [`crypto:hash_final/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#hash-final-1).
pub fn hash_final(state: HashState) -> Result(BitArray, Error) {
  hash_final_ffi(state)
}

/// One-shot HMAC.
///
/// See [`crypto:mac/4`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#mac-4).
pub fn mac_hmac(
  digest: HashAlgorithm,
  key: BitArray,
  data: BitArray,
) -> Result(BitArray, Error) {
  mac_hmac_ffi(digest, key, data)
}

/// One-shot HMAC-RIPEMD160 (accepted by AtomVM `mac/4` beyond `hash/2` digests).
///
/// See [`crypto:mac/4`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#mac-4).
pub fn mac_hmac_ripemd160(
  key: BitArray,
  data: BitArray,
) -> Result(BitArray, Error) {
  mac_hmac_ripemd160_ffi(key, data)
}

/// One-shot CMAC over an AES CBC/ECB subtype.
///
/// See [`crypto:mac/4`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#mac-4).
pub fn mac_cmac(
  cipher: CmacCipher,
  key: BitArray,
  data: BitArray,
) -> Result(BitArray, Error) {
  mac_cmac_ffi(cipher, key, data)
}

/// Start a streaming HMAC.
///
/// See [`crypto:mac_init/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#mac-init-3).
pub fn mac_init_hmac(
  digest: HashAlgorithm,
  key: BitArray,
) -> Result(MacState, Error) {
  mac_init_hmac_ffi(digest, key)
}

/// Start a streaming HMAC-RIPEMD160.
///
/// See [`crypto:mac_init/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#mac-init-3).
pub fn mac_init_hmac_ripemd160(key: BitArray) -> Result(MacState, Error) {
  mac_init_hmac_ripemd160_ffi(key)
}

/// Start a streaming CMAC.
///
/// See [`crypto:mac_init/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#mac-init-3).
pub fn mac_init_cmac(
  cipher: CmacCipher,
  key: BitArray,
) -> Result(MacState, Error) {
  mac_init_cmac_ffi(cipher, key)
}

/// Add `data` to a streaming MAC.
///
/// See [`crypto:mac_update/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#mac-update-2).
pub fn mac_update(state: MacState, data: BitArray) -> Result(MacState, Error) {
  mac_update_ffi(state, data)
}

/// Finalize a streaming MAC.
///
/// See [`crypto:mac_final/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#mac-final-1).
pub fn mac_final(state: MacState) -> Result(BitArray, Error) {
  mac_final_ffi(state)
}

/// Finalize a streaming MAC, truncating to `mac_length` bytes.
///
/// See [`crypto:mac_finalN/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#mac-finalN-2).
pub fn mac_final_n(
  state: MacState,
  mac_length: Int,
) -> Result(BitArray, Error) {
  mac_final_n_ffi(state, mac_length)
}

/// Cryptographically secure random bytes (preferred over deprecated
/// `atomvm:rand_bytes/1`).
///
/// See [`crypto:strong_rand_bytes/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#strong-rand-bytes-1).
pub fn strong_rand_bytes(n: Int) -> Result(BitArray, Error) {
  strong_rand_bytes_ffi(n)
}

/// One-shot encrypt/decrypt for ciphers that do not use an IV (ECB).
///
/// See [`crypto:crypto_one_time/4`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#crypto-one-time-4).
pub fn crypto_one_time(
  cipher: CipherNoIv,
  key: BitArray,
  data: BitArray,
  opts: CryptoOpts,
) -> Result(BitArray, Error) {
  let CryptoOpts(encrypt:, padding:) = opts
  crypto_one_time_ffi(cipher, key, data, encrypt, padding)
}

/// One-shot encrypt/decrypt for ciphers that use an IV.
///
/// See [`crypto:crypto_one_time/5`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#crypto-one-time-5).
pub fn crypto_one_time_iv(
  cipher: CipherIv,
  key: BitArray,
  iv: BitArray,
  data: BitArray,
  opts: CryptoOpts,
) -> Result(BitArray, Error) {
  let CryptoOpts(encrypt:, padding:) = opts
  crypto_one_time_iv_ffi(cipher, key, iv, data, encrypt, padding)
}

/// Start a streaming cipher for ciphers that do not use an IV (ECB).
///
/// Equivalent to upstream `crypto_init(Cipher, Key, <<>>, FlagOrOptions)`.
///
/// See [`crypto:crypto_init/3`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#crypto-init-3).
pub fn crypto_init(
  cipher: CipherNoIv,
  key: BitArray,
  opts: CryptoOpts,
) -> Result(CipherState, Error) {
  let CryptoOpts(encrypt:, padding:) = opts
  crypto_init_ffi(cipher, key, encrypt, padding)
}

/// Start a streaming cipher for ciphers that use an IV.
///
/// PKCS padding is supported only with CBC ciphers on AtomVM.
///
/// See [`crypto:crypto_init/4`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#crypto-init-4).
pub fn crypto_init_iv(
  cipher: CipherIv,
  key: BitArray,
  iv: BitArray,
  opts: CryptoOpts,
) -> Result(CipherState, Error) {
  let CryptoOpts(encrypt:, padding:) = opts
  crypto_init_iv_ffi(cipher, key, iv, encrypt, padding)
}

/// Feed `data` into a streaming cipher; returns ciphertext/plaintext produced
/// so far. Mutates `state` in place.
///
/// See [`crypto:crypto_update/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#crypto-update-2).
pub fn crypto_update(
  state: CipherState,
  data: BitArray,
) -> Result(BitArray, Error) {
  crypto_update_ffi(state, data)
}

/// Finalize a streaming cipher and return any remaining bytes.
///
/// After this call the state must not be reused on AtomVM (`badarg`).
///
/// See [`crypto:crypto_final/1`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#crypto-final-1).
pub fn crypto_final(state: CipherState) -> Result(BitArray, Error) {
  crypto_final_ffi(state)
}

/// AEAD encrypt with the default tag length.
///
/// Returns `#(ciphertext, tag)`.
///
/// See [`crypto:crypto_one_time_aead/6`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#crypto-one-time-aead-6).
pub fn crypto_one_time_aead_encrypt(
  cipher: CipherAead,
  key: BitArray,
  iv: BitArray,
  plaintext: BitArray,
  aad: BitArray,
) -> Result(#(BitArray, BitArray), Error) {
  crypto_one_time_aead_encrypt_ffi(cipher, key, iv, plaintext, aad)
}

/// AEAD encrypt with an explicit tag length in bytes.
///
/// Returns `#(ciphertext, tag)`.
///
/// See [`crypto:crypto_one_time_aead/7`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#crypto-one-time-aead-7).
pub fn crypto_one_time_aead_encrypt_tag_length(
  cipher: CipherAead,
  key: BitArray,
  iv: BitArray,
  plaintext: BitArray,
  aad: BitArray,
  tag_length: Int,
) -> Result(#(BitArray, BitArray), Error) {
  crypto_one_time_aead_encrypt_tag_length_ffi(
    cipher,
    key,
    iv,
    plaintext,
    aad,
    tag_length,
  )
}

/// AEAD decrypt; authentication failure becomes `Error(Failed)`.
///
/// See [`crypto:crypto_one_time_aead/7`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#crypto-one-time-aead-7).
pub fn crypto_one_time_aead_decrypt(
  cipher: CipherAead,
  key: BitArray,
  iv: BitArray,
  ciphertext: BitArray,
  aad: BitArray,
  tag: BitArray,
) -> Result(BitArray, Error) {
  crypto_one_time_aead_decrypt_ffi(cipher, key, iv, ciphertext, aad, tag)
}

/// PBKDF2-HMAC key derivation (RFC 8018 §5.2).
///
/// See [`crypto:pbkdf2_hmac/5`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#pbkdf2-hmac-5).
pub fn pbkdf2_hmac(
  digest: HashAlgorithm,
  password: BitArray,
  salt: BitArray,
  iterations: Int,
  key_len: Int,
) -> Result(BitArray, Error) {
  pbkdf2_hmac_ffi(digest, password, salt, iterations, key_len)
}

/// Generate an ECDH key pair for `curve`. Returns `#(public, private)`.
///
/// See [`crypto:generate_key/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#generate-key-2).
pub fn generate_key_ecdh(
  curve: EcCurve,
) -> Result(#(BitArray, BitArray), Error) {
  generate_key_ecdh_ffi(curve)
}

/// Generate an X25519 EDDH key pair. Returns `#(public, private)`.
///
/// See [`crypto:generate_key/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#generate-key-2).
pub fn generate_key_eddh() -> Result(#(BitArray, BitArray), Error) {
  generate_key_eddh_ffi()
}

/// Generate an Ed25519 key pair (libsodium build). Returns `#(public, private)`.
///
/// See [`crypto:generate_key/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#generate-key-2).
pub fn generate_key_eddsa() -> Result(#(BitArray, BitArray), Error) {
  generate_key_eddsa_ffi()
}

/// ECDH shared secret.
///
/// See [`crypto:compute_key/4`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#compute-key-4).
pub fn compute_key_ecdh(
  curve: EcCurve,
  other_public_key: BitArray,
  my_private_key: BitArray,
) -> Result(BitArray, Error) {
  compute_key_ecdh_ffi(curve, other_public_key, my_private_key)
}

/// X25519 EDDH shared secret.
///
/// See [`crypto:compute_key/4`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#compute-key-4).
pub fn compute_key_eddh(
  other_public_key: BitArray,
  my_private_key: BitArray,
) -> Result(BitArray, Error) {
  compute_key_eddh_ffi(other_public_key, my_private_key)
}

/// ECDSA sign. `curve` must be a Weierstrass curve (not `X25519`).
///
/// See [`crypto:sign/4`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#sign-4).
pub fn sign_ecdsa(
  digest: HashAlgorithm,
  msg: BitArray,
  private_key: BitArray,
  curve: EcCurve,
) -> Result(BitArray, Error) {
  sign_ecdsa_ffi(digest, msg, private_key, curve)
}

/// Ed25519 sign (`DigestType = none`; libsodium build).
///
/// See [`crypto:sign/4`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#sign-4).
pub fn sign_eddsa(
  msg: BitArray,
  private_key: BitArray,
) -> Result(BitArray, Error) {
  sign_eddsa_ffi(msg, private_key)
}

/// ECDSA verify. Invalid signatures return `Ok(False)`.
///
/// See [`crypto:verify/5`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#verify-5).
pub fn verify_ecdsa(
  digest: HashAlgorithm,
  msg: BitArray,
  signature: BitArray,
  public_key: BitArray,
  curve: EcCurve,
) -> Result(Bool, Error) {
  verify_ecdsa_ffi(digest, msg, signature, public_key, curve)
}

/// Ed25519 verify. Invalid signatures return `Ok(False)`.
///
/// See [`crypto:verify/5`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#verify-5).
pub fn verify_eddsa(
  msg: BitArray,
  signature: BitArray,
  public_key: BitArray,
) -> Result(Bool, Error) {
  verify_eddsa_ffi(msg, signature, public_key)
}

/// Constant-time equality for equal-length MAC/hash binaries.
///
/// See [`crypto:hash_equals/2`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#hash-equals-2).
pub fn hash_equals(a: BitArray, b: BitArray) -> Result(Bool, Error) {
  hash_equals_ffi(a, b)
}

/// Crypto library name/version tuples from the runtime.
///
/// See [`crypto:info_lib/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/crypto.html#info-lib-0).
pub fn info_lib() -> Result(List(LibInfo), Error) {
  info_lib_ffi()
}

@external(erlang, "atomvm_gleam_crypto_ffi", "hash")
fn hash_ffi(algorithm: HashAlgorithm, data: BitArray) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "hash_init")
fn hash_init_ffi(algorithm: HashAlgorithm) -> Result(HashState, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "hash_update")
fn hash_update_ffi(state: HashState, data: BitArray) -> Result(HashState, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "hash_final")
fn hash_final_ffi(state: HashState) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "mac_hmac")
fn mac_hmac_ffi(
  digest: HashAlgorithm,
  key: BitArray,
  data: BitArray,
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "mac_hmac_ripemd160")
fn mac_hmac_ripemd160_ffi(
  key: BitArray,
  data: BitArray,
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "mac_cmac")
fn mac_cmac_ffi(
  cipher: CmacCipher,
  key: BitArray,
  data: BitArray,
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "mac_init_hmac")
fn mac_init_hmac_ffi(
  digest: HashAlgorithm,
  key: BitArray,
) -> Result(MacState, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "mac_init_hmac_ripemd160")
fn mac_init_hmac_ripemd160_ffi(key: BitArray) -> Result(MacState, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "mac_init_cmac")
fn mac_init_cmac_ffi(
  cipher: CmacCipher,
  key: BitArray,
) -> Result(MacState, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "mac_update")
fn mac_update_ffi(state: MacState, data: BitArray) -> Result(MacState, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "mac_final")
fn mac_final_ffi(state: MacState) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "mac_final_n")
fn mac_final_n_ffi(state: MacState, mac_length: Int) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "strong_rand_bytes")
fn strong_rand_bytes_ffi(n: Int) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "crypto_one_time")
fn crypto_one_time_ffi(
  cipher: CipherNoIv,
  key: BitArray,
  data: BitArray,
  encrypt: Bool,
  padding: Option(Padding),
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "crypto_one_time_iv")
fn crypto_one_time_iv_ffi(
  cipher: CipherIv,
  key: BitArray,
  iv: BitArray,
  data: BitArray,
  encrypt: Bool,
  padding: Option(Padding),
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "crypto_init")
fn crypto_init_ffi(
  cipher: CipherNoIv,
  key: BitArray,
  encrypt: Bool,
  padding: Option(Padding),
) -> Result(CipherState, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "crypto_init_iv")
fn crypto_init_iv_ffi(
  cipher: CipherIv,
  key: BitArray,
  iv: BitArray,
  encrypt: Bool,
  padding: Option(Padding),
) -> Result(CipherState, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "crypto_update")
fn crypto_update_ffi(
  state: CipherState,
  data: BitArray,
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "crypto_final")
fn crypto_final_ffi(state: CipherState) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "crypto_one_time_aead_encrypt")
fn crypto_one_time_aead_encrypt_ffi(
  cipher: CipherAead,
  key: BitArray,
  iv: BitArray,
  plaintext: BitArray,
  aad: BitArray,
) -> Result(#(BitArray, BitArray), Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "crypto_one_time_aead_encrypt_tag_length")
fn crypto_one_time_aead_encrypt_tag_length_ffi(
  cipher: CipherAead,
  key: BitArray,
  iv: BitArray,
  plaintext: BitArray,
  aad: BitArray,
  tag_length: Int,
) -> Result(#(BitArray, BitArray), Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "crypto_one_time_aead_decrypt")
fn crypto_one_time_aead_decrypt_ffi(
  cipher: CipherAead,
  key: BitArray,
  iv: BitArray,
  ciphertext: BitArray,
  aad: BitArray,
  tag: BitArray,
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "pbkdf2_hmac")
fn pbkdf2_hmac_ffi(
  digest: HashAlgorithm,
  password: BitArray,
  salt: BitArray,
  iterations: Int,
  key_len: Int,
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "generate_key_ecdh")
fn generate_key_ecdh_ffi(curve: EcCurve) -> Result(#(BitArray, BitArray), Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "generate_key_eddh")
fn generate_key_eddh_ffi() -> Result(#(BitArray, BitArray), Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "generate_key_eddsa")
fn generate_key_eddsa_ffi() -> Result(#(BitArray, BitArray), Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "compute_key_ecdh")
fn compute_key_ecdh_ffi(
  curve: EcCurve,
  other_public_key: BitArray,
  my_private_key: BitArray,
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "compute_key_eddh")
fn compute_key_eddh_ffi(
  other_public_key: BitArray,
  my_private_key: BitArray,
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "sign_ecdsa")
fn sign_ecdsa_ffi(
  digest: HashAlgorithm,
  msg: BitArray,
  private_key: BitArray,
  curve: EcCurve,
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "sign_eddsa")
fn sign_eddsa_ffi(
  msg: BitArray,
  private_key: BitArray,
) -> Result(BitArray, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "verify_ecdsa")
fn verify_ecdsa_ffi(
  digest: HashAlgorithm,
  msg: BitArray,
  signature: BitArray,
  public_key: BitArray,
  curve: EcCurve,
) -> Result(Bool, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "verify_eddsa")
fn verify_eddsa_ffi(
  msg: BitArray,
  signature: BitArray,
  public_key: BitArray,
) -> Result(Bool, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "hash_equals")
fn hash_equals_ffi(a: BitArray, b: BitArray) -> Result(Bool, Error)

@external(erlang, "atomvm_gleam_crypto_ffi", "info_lib")
fn info_lib_ffi() -> Result(List(LibInfo), Error)
