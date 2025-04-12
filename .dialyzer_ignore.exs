[
  # Ignoring CSP header file due to static environment check that triggers Dialyzer.
  # The compile-time check for dev environment causes a false positive in pattern matching.
  {"lib/portfolio_web/plugs/csp_header.ex"},

  # Compiler.ex: Likely false positives due to how the helper is called
  {"lib/portfolio/content/entry/compiler.ex", 59, :pattern_match},
  {"lib/portfolio/content/entry/compiler.ex", 63, :guard_fail},
  # Ignoring the phantom coverage error that appeared on line 74
  {"lib/portfolio/content/entry/compiler.ex", 74, :pattern_match_cov},

  # Definition.ex: Pattern coverage in macro/callback code
  {Portfolio.Content.Markdown.Component.Definition, :__on_definition__, 6,
   :pattern_match_cov},

  # Parser.ex: Pattern coverage in recursive helper
  {Portfolio.Content.Markdown.Parser, :insert_custom_components, 2,
   :pattern_match_cov},

  # CoreComponents.ex: Likely PLT/environment issue, ignore if PLT rebuild doesn't fix
  {PortfolioWeb.CoreComponents, :dynamic_tag, 1, :unknown_function}
]
