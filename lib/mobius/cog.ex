defmodule Mobius.Cog do
  @moduledoc ~S"""
  Defines a cog.

  Cogs are small, self-contained services that implement a bot's logic. Cogs
  have two ways of handling Discord events: `listen/3` and `command/3`.

  `listen/3` instructs the cog to listen to specific events that are sent from
  Discord's API. Events are sent when users (humans or bots) interact with
  Discord. These include almost everything you can do on Discord from messages
  sent to users changing their username. For a complete list of events and the
  data associated with them see `Mobius.Core.Event`.

  `command/3` defines a command which can be used by users in text channels
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
    command "repeat", word: :string, times: :integer do
      word
      |> String.duplicate(times)
      |> String.trim()
      |> IO.puts()
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

  alias Mobius.Core.Command

  @doc false
  defmacro __using__(_call) do
    quote location: :keep do
      require Logger

      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :event_handlers, accumulate: true)
      Module.register_attribute(__MODULE__, :commands, accumulate: true)

      import unquote(__MODULE__), only: [listen: 2, listen: 3, command: 2, command: 3]

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

      listen :message_create, %{"content" => content} do
        case Command.execute_command(@commands, content) do
          {:ok, _} ->
            :ok

          {:too_few_args, command, received} ->
            Logger.info(
              "Too few arguments for command \"#{command.name}\". Expected #{
                Command.arg_count(command)
              } arguments, got #{received}."
            )

          {:invalid_args, errors} ->
            Enum.each(errors, fn {{arg_name, arg_type}, value} ->
              Logger.info(
                ~s(Invalid type for argument "#{arg_name}". Expected "#{Atom.to_string(arg_type)}", got "#{
                  value
                }".)
              )
            end)

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

        Logger.debug("Cog \"#{__MODULE__}\" subscribed to events #{inspect(event_names)}")

        {:ok, nil}
      end

      @impl true
      def handle_info({event_name, data}, state) when is_atom(event_name) and is_map(data) do
        Logger.debug("Cog \"#{__MODULE__}\" received event #{inspect(event_name)}")

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

      def unquote(name)(unquote(payload)), do: unquote(contents)
    end
  end

  @doc """
  Defines a command to be used by Discord users.

  The first parameter defines the name of the command as a single word (no
  spaces).

  The second parameter defines the list of arguments that the command accepts,
  along with their type. If a user passes more arguments than are defined by the
  command, the extraneous arguments will be ignored.

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

  ## Example
  ```elixir
  command "add", num1: :integer, num2: :integer do
    num1 + num2
  end
  ```

  In a Discord text channel:
  ```
  user: add 1 2
  myBot: 3
  user: add 1 hello
  myBot: Invalid type for argument "num2". Expected "integer", got "hello".
  """
  defmacro command(command_name, args \\ [], do: block) do
    # TODO: assert that the command name contains no whitespace
    handler_name = Command.command_handler_name(command_name)

    new_command = %Command{
      name: command_name,
      args: args,
      handler: Function.capture(__CALLER__.module, handler_name, length(args))
    }

    arg_vars =
      new_command
      |> Command.arg_names()
      |> Enum.map(&String.to_existing_atom/1)
      |> Enum.map(&Macro.var(&1, nil))
      |> Macro.escape()

    contents = Macro.escape(block, unquote: true)

    quote bind_quoted: [
            handler_name: handler_name,
            contents: contents,
            arg_vars: arg_vars,
            command: Macro.escape(new_command),
            line: __CALLER__.line,
            file: __CALLER__.file
          ] do
      existing_commands = Module.get_attribute(__MODULE__, :commands)

      if Module.defines?(__MODULE__, {handler_name, 0}) do
        reraise(
          %CompileError{
            line: line,
            file: file,
            description: "Command \"#{command.name}\" already exists."
          },
          []
        )
      else
        Module.put_attribute(__MODULE__, :commands, command)

        def unquote(handler_name)(unquote_splicing(arg_vars)), do: unquote(contents)
      end
    end
  end

  @doc false
  def __event_handler_name__(event_name, event_handlers) do
    handler_id = Enum.count(event_handlers, &(elem(&1, 0) === event_name))

    :"__mobius_event_#{event_name}_#{handler_id}__"
  end
end
