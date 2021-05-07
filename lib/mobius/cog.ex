defmodule Mobius.Cog do
  @moduledoc ~S"""
  Defines a cog.

  Cogs are small, self-contained services that implement a bot's logic. Cogs
  have two ways of handling Discord events: `listen/3` and `command/4`.

  `listen/3` instructs the cog to listen to specific events that are sent from
  Discord's API. Events are sent when users (humans or bots) interact with
  Discord. These include almost everything you can do on Discord from messages
  sent to users changing their username. For a complete list of events and the
  data associated with them see `Mobius.Core.Event`.

  `command/4` defines a command which can be used by users in text channels
  where the bot has the permission to read. These commands will execute the code
  specified in the do block of the command with its arguments.

  ## Example
  ```elixir
  defmodule MyCog do
    use Mobius.Cog

    # Every time a new user joins the server, greet the user
    listen :guild_member_add, %{"user" => user} do
      IO.puts("Welcome #{user["username"]}")
    end

    # Every time a user enters "repeat word times", repeat the word "word"
    # "times" times
    command "repeat", context, word: :string, times: :integer do
      reply =
        word
        |> String.duplicate(times)
        |> String.trim()
        |> IO.puts()

      send_message(%{content: reply}, context.channel_id)
    end
  end
  ```

  ## Notice about GenServer callbacks
  Cogs use GenServers underneath to handle communication with the other layers
  of the bot. While it is possible, it is not recommended to implement GenServer
  callbacks in your Cogs. If a Cog needs to handle any form of persistent
  state, it is recommended that this state be handled in another module, be it a
  GenServer or otherwise.

  Should you decide to implement GenServer callbacks in your cog, be aware that
  `Cog` already implements the `handle_info/2` callback, matching a two element
  tuple as the message (`{event_name, data}, state`), where `event_name` is an
  atom and `data` is a map. Please make sure that any other implementations of
  `handle_info/2` match a different pattern.
  """

  import Mobius.Actions.Message

  alias Mobius.Core.Cog
  alias Mobius.Core.Command

  require Logger

  @doc false
  defmacro __using__(_call) do
    quote location: :keep do
      require Logger

      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :event_handlers, accumulate: true)
      Module.register_attribute(__MODULE__, :commands, accumulate: true)

      import unquote(__MODULE__), only: [listen: 2, listen: 3, command: 2, command: 3, command: 4]

      @spec start_link(keyword) :: GenServer.on_start()
      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote location: :keep do
      use GenServer
      alias Mobius.Actions.Events
      alias Mobius.Services.Bot

      @computed_commands Command.preprocess_commands(@commands)

      @doc false
      def __cog__ do
        %Cog{
          module: __MODULE__,
          name: __MODULE__ |> Module.split() |> List.last(),
          description: @moduledoc,
          commands: @computed_commands
        }
      end

      listen :message_create, message do
        case Command.execute_command(@computed_commands, Bot.get_global_prefix!(), message) do
          {:ok, value} ->
            Mobius.Cog.handle_return(value, message)

          {:too_few_args, arities, received} ->
            Logger.info(
              "Wrong number of arguments. Expected one of #{
                arities |> Enum.map(&Integer.to_string/1) |> Enum.join(", ")
              } arguments, got #{received}."
            )

          {:invalid_args, [clause | _clauses]} ->
            Logger.info(
              ~s(Type mismatch for the command "#{clause.name}" with #{Command.arg_count(clause)} arguments)
            )

          :not_a_command ->
            :ok
        end
      end

      @impl true
      def init(_opts) do
        event_names =
          @event_handlers
          |> Enum.map(&elem(&1, 0))
          |> Enum.uniq()

        Events.subscribe(event_names)

        Logger.debug("Cog \"#{__cog__().name}\" subscribed to events #{inspect(event_names)}")

        {:ok, nil}
      end

      @impl true
      def handle_info({event_name, data}, state) when is_atom(event_name) and is_map(data) do
        Logger.debug("Cog \"#{__cog__().name}\" received event #{inspect(event_name)}")

        @event_handlers
        |> Enum.filter(&match?({^event_name, _handler}, &1))
        |> Enum.each(fn {_event_name, handler} -> apply(handler, [data]) end)

        {:noreply, state}
      end
    end
  end

  @doc ~S"""
  Defines an event handler for a Discord event.

  The second parameter, "payload", can be used to access the events payload.
  Please see `Mobius.Core.Event` for the full description of the different event
  payloads.

  ## Example
  ```elixir
  listen :message_create, %{"content" => content} do
    IO.puts("Message received: #{content}")
  end
  ```
  """
  defmacro listen(event_name, payload \\ quote(do: _), do: block) do
    payload = Macro.escape(payload)
    contents = Macro.escape(block, unquote: true)

    quote bind_quoted: [event_name: event_name, payload: payload, contents: contents] do
      existing_handlers = Module.get_attribute(__MODULE__, :event_handlers)

      name = Mobius.Cog.__event_handler_name__(event_name, existing_handlers)

      Module.put_attribute(
        __MODULE__,
        :event_handlers,
        {event_name, Function.capture(__MODULE__, name, 1)}
      )

      @doc false
      def unquote(name)(unquote(payload)), do: unquote(contents)
    end
  end

  @doc ~S"""
  Defines a command to be used by Discord users.

  The first parameter defines the name of the command as a single word
  (only lowercase alphanumeric characters and underscores are allowed).

  The second parameter defines the argument where the command context will be received.
  If omitted, the command context won't be available inside the command's body.

  The third parameter defines the list of arguments that the command accepts,
  along with their type. If a user passes more arguments than are defined by the
  command, the extraneous arguments will be ignored.
  If omitted, the command will be called regardless of what comes after the name
  of the command in the message.

  ## Command types

  The list of supported argument types is as follows:
  * `:string`
  * `:integer`

  If you wish to use a type that isn't supported by Mobius, `:string` should be
  used as a "catch all" type. You can then implement your own validation as part
  of the command body.

  If a user enters a command with an argument that doesn't match its
  corresponding type, Mobius will automatically reply to let the user know what
  the expected type is.

  ## Examples
  ```elixir
  command "printline" do
    IO.puts("\n")
  end

  command "ping", context do
    send_message(%{content: "Pong!"}, context.channel_id)
  end

  command "hello", you: :string do
    IO.inspect(you, label: "Your name is")
  end

  command "add", context, num1: :integer, num2: :integer do
    send_message(%{content: "#{num1 + num2}"}, context.channel_id)
  end
  ```

  In a Discord text channel:
  ```
  user: printline
  myBot (prints in the terminal):
  user: ping
  myBot: Pong!
  user: hello User
  myBot (prints in the terminal): Your name is: "User"
  user: add 1 2
  myBot: 3
  user: add 1 hello
  myBot: Invalid type for argument "num2". Expected "integer", got "hello".
  """
  defmacro command(command_name, context, args, do: block) do
    if not Regex.match?(~r/^[[:lower:][:digit:]_]+$/, command_name) do
      raise CompileError,
        description:
          "Command names must only contain lowercase alphanumeric characters or underscores"
    end

    quote bind_quoted: [
            command_name: command_name,
            contents: Macro.escape(block, unquote: true),
            args: Macro.escape(args),
            context: Macro.escape(context),
            module: __CALLER__.module
          ] do
      handler_name = Command.command_handler_name(command_name)

      # +1 to the length of args to leave room for the context
      new_command = %Command{
        name: command_name,
        description: Mobius.Cog.pop_doc(module),
        args: args,
        handler: Function.capture(module, handler_name, length(args) + 1)
      }

      arg_vars = Enum.map(args, fn {variable, type} -> {type, Macro.var(variable, nil)} end)

      Module.put_attribute(__MODULE__, :commands, new_command)

      @doc false
      def unquote(handler_name)(unquote(context), unquote_splicing(arg_vars)),
        do: unquote(contents)
    end
  end

  defmacro command(command_name, args, do: block) when is_list(args) do
    quote do
      command(unquote(command_name), _, unquote(args), do: unquote(block))
    end
  end

  defmacro command(command_name, context, do: block) do
    quote do
      command(unquote(command_name), unquote(context), [], do: unquote(block))
    end
  end

  defmacro command(command_name, do: block) do
    quote do
      command(unquote(command_name), _, [], do: unquote(block))
    end
  end

  @doc false
  def handle_return(:ok, _context), do: :ok
  def handle_return({:reply, body}, context), do: send_message(body, context.channel_id)
  def handle_return(value, _context), do: Logger.warn("Invalid return: #{inspect(value)}")

  @doc false
  def __event_handler_name__(event_name, event_handlers) do
    handler_id = Enum.count(event_handlers, &(elem(&1, 0) === event_name))

    :"__mobius_event_#{event_name}_#{handler_id}__"
  end

  @doc false
  def pop_doc(module) do
    doc =
      case Module.get_attribute(module, :doc) do
        {_line, false} -> false
        {_line, doc} -> doc
        _ -> nil
      end

    Module.delete_attribute(module, :doc)
    doc
  end
end
