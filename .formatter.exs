# Used by "mix format"
locals_without_parens = [
  # Mobius.Cog
  listen: 2,
  listen: 3,
  command: 2,
  command: 3
]

[
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
