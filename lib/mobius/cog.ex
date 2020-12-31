defmodule Mobius.Cog do
  defmacro __using__(_call) do
    quote do
      require Logger

      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :event_handlers, accumulate: true)

      import unquote(__MODULE__), only: [listen: 2, listen: 3]

      # TODO: replace &IO.inspect/1 with command handler
      listen :message_create, %{"content" => content} do
        IO.inspect(content)
      end

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

  defmacro listen(event_name, var \\ quote(do: _), [do: block]) do
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
end
