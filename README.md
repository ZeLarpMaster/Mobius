# Mobius

An Elixir framework for creating Discord bots in a modular way

## Usage
The package can be installed by adding `mobius` to your list of dependencies in `mix.exs`:

`{:mobius, git: "https://github.com/ZeLarpMaster/Mobius.git"}`

## Contributing
You need [Elixir 1.10 or above](https://elixir-lang.org/install.html) installed.

You will also need a [bot account and its token](https://discordpy.readthedocs.io/en/latest/discord.html).
The token will need to be in an environment variable named `MOBIUS_BOT_TOKEN`.

Commands to execute after cloning to install all the requirements:
* `mix deps.get` and say yes to install hex if it prompts you
* `mix compile` and say yes to install rebar if it prompts you
* `mix test` to ensure everything works as expected

`iex -S mix` runs the bot in debug mode where you can write code in an interactive shell while it runs
