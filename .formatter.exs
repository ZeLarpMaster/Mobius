# Used by "mix format"
locals_without_parens = [
  # Mobius.Services.Cog
  listen: 2,
  listen: 3
]

[
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
