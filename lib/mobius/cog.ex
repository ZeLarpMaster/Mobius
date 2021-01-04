defmodule Mobius.Cog do
  @moduledoc false

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
        case Command.parse_command(@commands, content) do
          {:ok, command, arg_values} ->
            Command.execute(command, arg_values)

          {:too_few_args, command, received} ->
            Logger.info(
              "Too few arguments for command \"#{command.name}\". Expected #{
                Command.arg_count(command)
              } arguments, got #{received}."
            )

          {:invalid_args, errors} ->
            errors
            |> Enum.each(fn {{arg_name, arg_type}, value} ->
              Logger.info(
                "Invalid type for argument \"#{arg_name}\". Expected \"#{Atom.to_string(arg_type)}\", got \"#{
                  value
                }\"."
              )
            end)

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
        |> Enum.each(fn {_event_name, handler} -> apply(handler, [data]) end)

        {:noreply, state}
      end
    end
  end

  defmacro listen(event_name, var \\ quote(do: _), do: block) do
    var = Macro.escape(var)
    contents = Macro.escape(block, unquote: true)

    quote bind_quoted: [event_name: event_name, var: var, contents: contents] do
      existing_handlers = Module.get_attribute(__MODULE__, :event_handlers)

      name = Mobius.Cog.event_handler_name(event_name, existing_handlers)

      Module.put_attribute(
        __MODULE__,
        :event_handlers,
        {event_name, Function.capture(__MODULE__, name, 1)}
      )

      def unquote(name)(unquote(var)), do: unquote(contents)
    end
  end

  defmacro command(command_name, args \\ [], do: block) do
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
            command: Macro.escape(new_command)
          ] do
      existing_commands = Module.get_attribute(__MODULE__, :commands)

      if Module.defines?(__MODULE__, {handler_name, 0}) do
        IO.warn(
          "Command \"#{command.name}\" already exists. Duplicated command will be ignored.",
          Macro.Env.stacktrace(__ENV__)
        )
      else
        Module.put_attribute(__MODULE__, :commands, command)

        def unquote(handler_name)(unquote_splicing(arg_vars)), do: unquote(contents)
      end
    end
  end

  def event_handler_name(event_name, event_handlers) do
    handler_id =
      event_handlers
      |> Enum.group_by(&elem(&1, 0))
      |> Map.get(event_name, [])
      |> length()

    :"mobius_event_#{Atom.to_string(event_name)}_#{Integer.to_string(handler_id)}"
  end
end
