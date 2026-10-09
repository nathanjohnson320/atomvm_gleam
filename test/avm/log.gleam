//// Harness console logging.

@external(erlang, "erlang", "display")
fn display(term: String) -> String

pub fn line(text: String) -> Nil {
  let _ = display(text)
  Nil
}
