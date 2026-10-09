-module(avm_test_env_ffi).
-export([try_random/0]).

%% Soft-call atomvm:random/0 — some builds omit the NIF.
try_random() ->
    try
        {ok, atomvm:random()}
    catch
        error:undef ->
            {error, nil};
        error:not_supported ->
            {error, nil};
        _:_ ->
            {error, nil}
    end.
