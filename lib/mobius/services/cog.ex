defmodule Mobius.Services.Cog do
  defmacro __using__(_call) do
    quote do
      require Logger

      @before_compile unquote(__MODULE__)

      Module.put_attribute(__MODULE__, :event_handlers, %{})

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

        Events.subscribe(event_names)

        Logger.debug("Cog \"#{__MODULE__}\" subscribed to events #{inspect(event_names)}")

        {:ok, nil}
      end

      @impl true
      def handle_info({event_name, data}, state) do
        Logger.debug("Cog \"#{__MODULE__}\" received event #{inspect(event_name)}")

        @event_handlers
        |> Map.get(event_name, [])
        |> Enum.each(fn handler -> apply(__MODULE__, handler, [data]) end)

        {:noreply, state}
      end
    end
  end

  defmacro listen(event_name, var \\ quote(do: _), contents) do
    contents =
      case contents do
        [do: block] ->
          quote do
            unquote(block)
            :ok
          end

        _ ->
          quote do
            try(unquote(contents))
            :ok
          end
      end

    var = Macro.escape(var)
    contents = Macro.escape(contents, unquote: true)

    quote bind_quoted: [event_name: event_name, var: var, contents: contents] do
      existing_handlers = Module.get_attribute(__MODULE__, :event_handlers)

      handler_id =
        existing_handlers
        |> Map.get(event_name, [])
        |> length()

      name = :"#{Atom.to_string(event_name)}#{Integer.to_string(handler_id)}"

      updated_handlers =
        existing_handlers
        |> Map.update(event_name, [name], fn handlers ->
          [name | handlers]
        end)

      Module.put_attribute(__MODULE__, :event_handlers, updated_handlers)

      def unquote(name)(unquote(var)), do: unquote(contents)
    end
  end
end
