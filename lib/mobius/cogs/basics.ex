defmodule Mobius.Cogs.Basics do
  @moduledoc "Basic features of the bot"

  use Mobius.Cog

  @doc ~s(Replies with "Pong!")
  command "ping" do
    {:reply, %{content: "Pong!"}}
  end

  @doc "Shows general information about this bot"
  command "info" do
    {:reply, %{content: "stuff"}}
  end

  @doc "Gives an invite url for this bot"
  command "invite" do
    content = """
    <invite url>

    You can edit the permissions using a tool such as https://discordapi.com/permissions.html
    Your client ID is: <client id>
    """

    {:reply, %{content: content}}
  end

  @doc "Shows the bot's uptime"
  command "uptime" do
    duration =
      :erlang.statistics(:wall_clock)
      |> elem(0)
      |> Timex.Duration.from_milliseconds()

    formatted_duration =
      duration
      # Truncate on seconds
      |> Timex.Duration.to_seconds(truncate: true)
      |> Timex.Duration.from_seconds()
      |> Timex.format_duration(:humanized)

    datetime =
      Timex.now()
      |> Timex.subtract(duration)
      |> Timex.format!("{D} {Mshort} {YYYY} {h24}:{m}:{s} {Zabbr}")

    {:reply, %{content: "I've been running for **#{formatted_duration}** (since #{datetime})"}}
  end
end
