defmodule DemoBot.Context do
  @moduledoc false

  alias Mobius.Bot
  alias Mobius.Api.Client

  @enforce_keys [:client, :bot, :message]
  defstruct [:client, :bot, :message]

  @type t :: %__MODULE__{
          client: Client.client(),
          bot: Bot.t(),
          message: map
        }
end

defmodule DemoBot do
  @moduledoc false

  use GenServer

  alias Mobius.Api
  alias Mobius.Bot
  alias DemoBot.Commands
  alias DemoBot.Context
  alias DemoBot.TaskSupervisor

  @prefix "!"

  @type state :: %{bot: Bot.t()}
  @type reply :: {:reply, keyword} | {:react, String.t()} | :noreply

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec init(keyword) :: {:ok, state(), {:continue, atom}}
  def init(opts) do
    bot = Bot.start_bot(:demo_bot, Keyword.fetch!(opts, :token))

    Bot.subscribe_events(bot, [:READY])

    {:ok, %{bot: bot}, {:continue, :wait_until_ready}}
  end

  @spec handle_continue(:wait_until_ready, state()) :: {:noreply, state()}
  def handle_continue(:wait_until_ready, state) do
    receive do
      {:READY, _} -> :ok
    end

    Bot.unsubscribe_events(state.bot)
    Bot.subscribe_events(state.bot, [:MESSAGE_CREATE])

    Bot.update_status(state.bot, %Mobius.Models.Status{game: %{"type" => 0, "name" => "Ready!"}})

    {:noreply, state}
  end

  def handle_info({:MESSAGE_CREATE, %{"content" => @prefix <> command} = message}, state) do
    client = state.bot.client

    Task.start(fn ->
      ctx = %Context{bot: state.bot, client: client, message: message}

      case handle_command(ctx, command) do
        {:reply, params} ->
          {:ok, _} = Api.Message.create_message(client, message["channel_id"], params)

        {:react, emoji} ->
          :ok = Api.Reaction.create_reaction(client, message["channel_id"], message["id"], emoji)

        :noreply ->
          nil
      end
    end)

    {:noreply, state}
  end

  def handle_info({:MESSAGE_CREATE, _}, state), do: {:noreply, state}

  defp handle_command(ctx, command) do
    %Task{ref: ref} =
      Task.Supervisor.async_nolink(TaskSupervisor, Commands, :handle_command, [ctx, command])

    receive do
      {^ref, reply} ->
        # Task success
        Process.demonitor(ref, [:flush])
        reply

      {:DOWN, ^ref, :process, _pid, reason} ->
        # Task failed
        {:reply, content: "Command failed with reason: #{inspect(reason)}"}
    end
  end
end

defmodule DemoBot.Commands do
  @moduledoc false

  alias Mobius.Api
  alias Mobius.Bot
  alias DemoBot.Context

  @spec handle_command(Context.t(), String.t()) :: DemoBot.reply()
  def handle_command(_ctx, _command)

  def handle_command(ctx, "ping") do
    pings = Bot.get_pings(ctx.bot)
    ping = div(Enum.sum(pings), length(pings))

    {:reply, content: "Pong! (#{ping} ms)"}
  end

  def handle_command(_ctx, "uptime") do
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    uptime_string = ms_to_string(uptime_ms)

    {:reply, content: "The bot has been running for: #{uptime_string}"}
  end

  def handle_command(_ctx, "error") do
    _ = String.to_integer("Hello")
    {:react, "✅"}
  end

  def handle_command(ctx, "owner?") do
    owners = get_owners(Api.Gateway.get_app_info(ctx.client))
    {:reply, content: "Owner ids: #{inspect(owners)}"}
  end

  def handle_command(ctx, "setschedulers " <> num) do
    integer = parse_int(num)

    owners = get_owners(Api.Gateway.get_app_info(ctx.client))

    cond do
      ctx.message["author"]["id"] not in owners ->
        {:react, "🚫"}

      is_integer(integer) and 1 <= integer and integer <= 8 ->
        change_schedulers(integer)
        {:react, "✅"}

      true ->
        {:react, "❌"}
    end
  end

  def handle_command(_ctx, "whatsacpu?"), do: cpu_loop()

  @valid_statuses ["online", "dnd", "idle", "invisible"]
  def handle_command(ctx, "setstatus " <> status) when status in @valid_statuses do
    case Bot.update_status(ctx.bot, %Mobius.Models.Status{status: status}) do
      [:ok] -> {:react, "✅"}
      [{:error, :ratelimited}] -> {:react, "⏳"}
    end
  end

  def handle_command(_ctx, "setstatus " <> _) do
    {:react, "❌"}
  end

  def handle_command(ctx, "setgame " <> game) do
    status = %Mobius.Models.Status{game: %{"name" => game, "type" => 0}}

    case Bot.update_status(ctx.bot, status) do
      [:ok] -> {:react, "✅"}
      [{:error, :ratelimited}] -> {:react, "⏳"}
    end
  end

  def handle_command(ctx, "cleanup " <> number) do
    case parse_int(number) do
      integer when is_integer(integer) and integer <= 100 ->
        Task.start(fn ->
          delete_messages(ctx, ctx.message["channel_id"], ctx.message["id"], integer)
        end)

        {:react, "✅"}

      _ ->
        {:react, "❌"}
    end
  end

  def handle_command(_ctx, _command), do: :noreply

  #####################
  # Utility functions #
  #####################
  defp cpu_loop(value \\ 0), do: cpu_loop(value + 1)

  defp change_schedulers(schedulers) when is_integer(schedulers) do
    :erlang.system_flag(:schedulers_online, schedulers)
    :erlang.system_flag(:dirty_cpu_schedulers_online, schedulers)
  end

  defp parse_int(num) do
    case Integer.parse(num) do
      {int, ""} -> int
      _ -> nil
    end
  end

  defp get_owners({:ok, app}) do
    if :team_user in app.owner.flags do
      Enum.map(app.team.members, fn member -> member.user.id end)
    else
      [app.owner.id]
    end
  end

  defp delete_messages(ctx, channel_id, before, amount) do
    {:ok, list} = Api.Message.list_messages(ctx.client, channel_id, before: before, limit: amount)

    case list do
      [] ->
        :ok

      [message] ->
        Api.Message.delete_message(ctx.client, channel_id, message.id)

      list when is_list(list) and length(list) > 1 ->
        Api.Message.bulk_delete_messages(ctx.client, channel_id, Enum.map(list, & &1.id))
    end
  end

  defp ms_to_string(ms) do
    Enum.reduce([{1000, "ms"}, {60, "s"}, {60, "m"}, {24, "h"}, {0, "d"}], {ms, ""}, fn
      _, {0, out} ->
        {0, out}

      {0, name}, {time, out} ->
        {0, to_string(time) <> name <> out}

      {num, name}, {time, out} ->
        out = to_string(rem(time, num)) <> name <> out
        {div(time, num), out}
    end)
    |> elem(1)
  end
end

Supervisor.start_link(
  [
    {Task.Supervisor, name: DemoBot.TaskSupervisor},
    {DemoBot, token: Application.fetch_env!(:mobius, :token)}
  ],
  strategy: :one_for_one,
  name: DemoBot.Supervisor
)

require IEx

if not IEx.started?() do
  IO.puts("Press ENTER or (Ctrl+C twice) to stop the bot")
  IO.gets("")
end
