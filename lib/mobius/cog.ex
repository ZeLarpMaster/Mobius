defmodule Mobius.Cog do
  alias Mobius.Core.Command

  defmacro __using__(_call) do
    quote do
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

  defmacro __before_compile__(_env) do
    quote do
      use GenServer
      alias Mobius.Actions.Events

      listen :message_create, %{"content" => content} do
        case Command.validate_command(@commands, content) do
          {:ok, command} ->
            Command.execute(command, __MODULE__)

          {:too_few_args, command_name, expected, received} ->
            Logger.info(
              "Too few arguments for command \"#{command_name}\". Expected #{expected} arguments, got #{
                received
              }."
            )

          _ ->
            nil
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
      def handle_info({event_name, data}, state) do
        Logger.debug("Cog \"#{__MODULE__}\" received event #{inspect(event_name)}")

        @event_handlers
        |> Enum.filter(&match?({^event_name, _handler}, &1))
        |> Enum.each(fn {_event_name, handler} -> apply(__MODULE__, handler, [data]) end)

        {:noreply, state}
      end
    end
  end

  defmacro listen(event_name, var \\ quote(do: _), do: block) do
    var = Macro.escape(var)
    contents = Macro.escape(block, unquote: true)

    quote bind_quoted: [event_name: event_name, var: var, contents: contents] do
      existing_handlers = Module.get_attribute(__MODULE__, :event_handlers)

      handler_id = length(existing_handlers)
      name = :"#{Atom.to_string(event_name)}#{Integer.to_string(handler_id)}"

      Module.put_attribute(__MODULE__, :event_handlers, {event_name, name})

      def unquote(name)(unquote(var)), do: unquote(contents)
    end
  end

  @spec command(String.t(), Macro.input(), do: Macro.input()) :: Macro.output()
  defmacro command(command_name, var \\ quote(do: _), do: block) do
    arg_names = Command.get_command_arg_names(var)
    var = Macro.escape(var)
    contents = Macro.escape(block, unquote: true)
    name = Command.command_handler_name(command_name)

    quote bind_quoted: [
            command_name: command_name,
            name: name,
            contents: contents,
            var: var,
            arg_names: arg_names
          ] do
      existing_commands = Module.get_attribute(__MODULE__, :commands)

      if Module.defines?(__MODULE__, {name, 0}) do
        IO.warn(
          "Command \"#{command_name}\" already exists. Duplicated command will be ignored.",
          Macro.Env.stacktrace(__ENV__)
        )
      else
        Module.put_attribute(__MODULE__, :commands, {command_name, name, arg_names})
        def unquote(name)(unquote(var)), do: unquote(contents)
      end
    end
  end
end
