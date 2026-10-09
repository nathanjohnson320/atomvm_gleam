//// HTML5 register/unregister — requires a browser DOM.

import avm/check.{type Failure}

/// Node/wasm CI has no Window/Document; suite is a no-op.
/// APIs are excluded from the coverage gate (see scripts/coverage_report.py).
pub fn run() -> Result(Nil, Failure) {
  check.ok()
}
