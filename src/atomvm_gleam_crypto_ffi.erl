-module(atomvm_gleam_crypto_ffi).
-export([
    hash/2,
    hash_init/1,
    hash_update/2,
    hash_final/1,
    mac_hmac/3,
    mac_hmac_ripemd160/2,
    mac_cmac/3,
    mac_init_hmac/2,
    mac_init_hmac_ripemd160/1,
    mac_init_cmac/2,
    mac_update/2,
    mac_final/1,
    mac_final_n/2,
    strong_rand_bytes/1,
    crypto_one_time/5,
    crypto_one_time_iv/6,
    crypto_init/4,
    crypto_init_iv/5,
    crypto_update/2,
    crypto_final/1,
    crypto_one_time_aead_encrypt/5,
    crypto_one_time_aead_encrypt_tag_length/6,
    crypto_one_time_aead_decrypt/6,
    pbkdf2_hmac/5,
    generate_key_ecdh/1,
    generate_key_eddh/0,
    generate_key_eddsa/0,
    compute_key_ecdh/3,
    compute_key_eddh/2,
    sign_ecdsa/4,
    sign_eddsa/2,
    verify_ecdsa/5,
    verify_eddsa/3,
    hash_equals/2,
    info_lib/0,
    map_raised/1
]).

hash(Algorithm, Data) ->
    wrap_binary(fun() -> crypto:hash(Algorithm, Data) end).

hash_init(Algorithm) ->
    wrap_binary(fun() -> crypto:hash_init(Algorithm) end).

hash_update(State, Data) ->
    wrap_binary(fun() -> crypto:hash_update(State, Data) end).

hash_final(State) ->
    wrap_binary(fun() -> crypto:hash_final(State) end).

mac_hmac(Digest, Key, Data) ->
    wrap_binary(fun() -> crypto:mac(hmac, Digest, Key, Data) end).

mac_hmac_ripemd160(Key, Data) ->
    wrap_binary(fun() -> crypto:mac(hmac, ripemd160, Key, Data) end).

mac_cmac(Cipher, Key, Data) ->
    wrap_binary(fun() -> crypto:mac(cmac, cmac_cipher(Cipher), Key, Data) end).

mac_init_hmac(Digest, Key) ->
    wrap_binary(fun() -> crypto:mac_init(hmac, Digest, Key) end).

mac_init_hmac_ripemd160(Key) ->
    wrap_binary(fun() -> crypto:mac_init(hmac, ripemd160, Key) end).

mac_init_cmac(Cipher, Key) ->
    wrap_binary(fun() -> crypto:mac_init(cmac, cmac_cipher(Cipher), Key) end).

mac_update(State, Data) ->
    wrap_binary(fun() -> crypto:mac_update(State, Data) end).

mac_final(State) ->
    wrap_binary(fun() -> crypto:mac_final(State) end).

mac_final_n(State, MacLength) ->
    wrap_binary(fun() -> crypto:mac_finalN(State, MacLength) end).

strong_rand_bytes(N) ->
    wrap_binary(fun() -> crypto:strong_rand_bytes(N) end).

crypto_one_time(Cipher, Key, Data, Encrypt, Padding) ->
    wrap_binary(fun() ->
        crypto:crypto_one_time(
            cipher(Cipher), Key, Data, crypto_opts(Encrypt, Padding)
        )
    end).

crypto_one_time_iv(Cipher, Key, IV, Data, Encrypt, Padding) ->
    wrap_binary(fun() ->
        crypto:crypto_one_time(
            cipher(Cipher), Key, IV, Data, crypto_opts(Encrypt, Padding)
        )
    end).

crypto_init(Cipher, Key, Encrypt, Padding) ->
    wrap_binary(fun() ->
        crypto:crypto_init(cipher(Cipher), Key, crypto_opts(Encrypt, Padding))
    end).

crypto_init_iv(Cipher, Key, IV, Encrypt, Padding) ->
    wrap_binary(fun() ->
        crypto:crypto_init(
            cipher(Cipher), Key, IV, crypto_opts(Encrypt, Padding)
        )
    end).

crypto_update(State, Data) ->
    wrap_binary(fun() -> crypto:crypto_update(State, Data) end).

crypto_final(State) ->
    wrap_binary(fun() -> crypto:crypto_final(State) end).

crypto_one_time_aead_encrypt(Cipher, Key, IV, Plaintext, AAD) ->
    wrap_binary(fun() ->
        crypto:crypto_one_time_aead(
            cipher(Cipher), Key, IV, Plaintext, AAD, true
        )
    end).

crypto_one_time_aead_encrypt_tag_length(Cipher, Key, IV, Plaintext, AAD, TagLength) ->
    wrap_binary(fun() ->
        crypto:crypto_one_time_aead(
            cipher(Cipher), Key, IV, Plaintext, AAD, TagLength, true
        )
    end).

crypto_one_time_aead_decrypt(Cipher, Key, IV, Ciphertext, AAD, Tag) ->
    try
        case
            crypto:crypto_one_time_aead(
                cipher(Cipher), Key, IV, Ciphertext, AAD, Tag, false
            )
        of
            error ->
                {error, failed};
            Plaintext when is_binary(Plaintext) ->
                {ok, Plaintext};
            Other ->
                wrap_reason(Other)
        end
    catch
        error:badarg ->
            {error, badarg};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

pbkdf2_hmac(Digest, Password, Salt, Iterations, KeyLen) ->
    wrap_binary(fun() ->
        crypto:pbkdf2_hmac(Digest, Password, Salt, Iterations, KeyLen)
    end).

generate_key_ecdh(Curve) ->
    wrap_binary(fun() -> crypto:generate_key(ecdh, curve(Curve)) end).

generate_key_eddh() ->
    wrap_binary(fun() -> crypto:generate_key(eddh, x25519) end).

generate_key_eddsa() ->
    wrap_binary(fun() -> crypto:generate_key(eddsa, ed25519) end).

compute_key_ecdh(Curve, OtherPublicKey, MyPrivateKey) ->
    wrap_binary(fun() ->
        crypto:compute_key(ecdh, OtherPublicKey, MyPrivateKey, curve(Curve))
    end).

compute_key_eddh(OtherPublicKey, MyPrivateKey) ->
    wrap_binary(fun() ->
        crypto:compute_key(eddh, OtherPublicKey, MyPrivateKey, x25519)
    end).

sign_ecdsa(Digest, Msg, PrivateKey, Curve) ->
    wrap_binary(fun() ->
        crypto:sign(ecdsa, Digest, Msg, [PrivateKey, curve(Curve)])
    end).

sign_eddsa(Msg, PrivateKey) ->
    wrap_binary(fun() ->
        crypto:sign(eddsa, none, Msg, [PrivateKey, ed25519])
    end).

verify_ecdsa(Digest, Msg, Signature, PublicKey, Curve) ->
    wrap_binary(fun() ->
        crypto:verify(ecdsa, Digest, Msg, Signature, [PublicKey, curve(Curve)])
    end).

verify_eddsa(Msg, Signature, PublicKey) ->
    wrap_binary(fun() ->
        crypto:verify(eddsa, none, Msg, Signature, [PublicKey, ed25519])
    end).

hash_equals(A, B) ->
    wrap_binary(fun() -> crypto:hash_equals(A, B) end).

info_lib() ->
    try
        Libs = crypto:info_lib(),
        {ok, [{lib_info, Name, VerNum, VerStr} || {Name, VerNum, VerStr} <- Libs]}
    catch
        error:badarg ->
            {error, badarg};
        error:not_supported ->
            {error, not_supported};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        _:_ ->
            {error, failed}
    end.

map_raised(Reason) when is_atom(Reason) ->
    wrap_binary(fun() -> error(Reason) end).

crypto_opts(Encrypt, none) ->
    Encrypt;
crypto_opts(Encrypt, {some, Padding}) ->
    [{encrypt, Encrypt}, {padding, padding(Padding)}].

padding(no_padding) ->
    none;
padding(pkcs_padding) ->
    pkcs_padding.

%% Gleam turns Aes128Cbc into aes128_cbc; AtomVM wants aes_128_cbc.
cipher(aes128_ecb) -> aes_128_ecb;
cipher(aes192_ecb) -> aes_192_ecb;
cipher(aes256_ecb) -> aes_256_ecb;
cipher(aes128_cbc) -> aes_128_cbc;
cipher(aes192_cbc) -> aes_192_cbc;
cipher(aes256_cbc) -> aes_256_cbc;
cipher(aes128_cfb128) -> aes_128_cfb128;
cipher(aes192_cfb128) -> aes_192_cfb128;
cipher(aes256_cfb128) -> aes_256_cfb128;
cipher(aes128_ctr) -> aes_128_ctr;
cipher(aes192_ctr) -> aes_192_ctr;
cipher(aes256_ctr) -> aes_256_ctr;
cipher(aes128_ofb) -> aes_128_ofb;
cipher(aes192_ofb) -> aes_192_ofb;
cipher(aes256_ofb) -> aes_256_ofb;
cipher(aes128_gcm) -> aes_128_gcm;
cipher(aes192_gcm) -> aes_192_gcm;
cipher(aes256_gcm) -> aes_256_gcm;
cipher(aes128_ccm) -> aes_128_ccm;
cipher(aes192_ccm) -> aes_192_ccm;
cipher(aes256_ccm) -> aes_256_ccm;
cipher(chacha20_poly1305) -> chacha20_poly1305.

cmac_cipher(cmac_aes128_cbc) ->
    aes_128_cbc;
cmac_cipher(cmac_aes128_ecb) ->
    aes_128_ecb;
cmac_cipher(cmac_aes192_cbc) ->
    aes_192_cbc;
cmac_cipher(cmac_aes192_ecb) ->
    aes_192_ecb;
cmac_cipher(cmac_aes256_cbc) ->
    aes_256_cbc;
cmac_cipher(cmac_aes256_ecb) ->
    aes_256_ecb.

curve(brainpool_p256r1) ->
    brainpoolP256r1;
curve(brainpool_p384r1) ->
    brainpoolP384r1;
curve(brainpool_p512r1) ->
    brainpoolP512r1;
curve(Curve) ->
    Curve.

wrap_binary(Fun) ->
    try
        {ok, Fun()}
    catch
        error:badarg ->
            {error, badarg};
        error:not_supported ->
            {error, not_supported};
        error:Reason when is_atom(Reason) ->
            wrap_reason(Reason);
        error:{Error, _} when is_atom(Error) ->
            wrap_reason(Error);
        _:_ ->
            {error, failed}
    end.

wrap_reason(not_supported) ->
    {error, not_supported};
wrap_reason(badarg) ->
    {error, badarg};
wrap_reason(timeout) ->
    {error, timeout};
wrap_reason(failed) ->
    {error, failed};
wrap_reason(Reason) when is_atom(Reason) ->
    {error, {other, atom_to_binary(Reason, utf8)}};
wrap_reason(Reason) when is_binary(Reason) ->
    {error, {other, Reason}};
wrap_reason(Reason) ->
    {error, {other, iolist_to_binary(io_lib:format("~p", [Reason]))}}.
