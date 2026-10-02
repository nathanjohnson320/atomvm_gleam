/// Thin wrappers for AtomVM `:ssl` (needed before HTTPS).
///
/// See [Module ssl](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/ssl.html).

/// Start the SSL application.
///
/// See [`ssl:start/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/ssl.html#start-0).
@external(erlang, "atomvm_gleam_ssl_ffi", "start")
pub fn start() -> Nil

/// Stop the SSL application.
///
/// See [`ssl:stop/0`](https://doc.atomvm.org/release-0.7/apidocs/erlang/estdlib/ssl.html#stop-0).
@external(erlang, "atomvm_gleam_ssl_ffi", "stop")
pub fn stop() -> Nil
