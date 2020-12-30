defmodule Mobius.Services.Cog do
  defmacro __using__(_call) do
    quote do
      use GenServer
      require Logger

      alias Mobius.Actions.Events

      :persistent_term.put(:event_handlers, %{})

      import unquote(__MODULE__), only: [listen: 2]

      # TODO: replace &IO.inspect/1 with command handler
      listen :message_create do
        IO.inspect("message created")
        # IO.inspect(data)
      end

      @spec start_link(keyword) :: GenServer.on_start()
      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl true
      def init(_opts) do
        event_names =
          :persistent_term.get(:event_handlers)
          |> Enum.map(&elem(&1, 0))

        Events.subscribe(event_names)

        Logger.debug("Cog \"#{__MODULE__}\" subscribed to events #{inspect(event_names)}")

        {:ok, nil}
      end

      @impl true
      def handle_info({event_name, data}, state) do
        Logger.debug("Cog \"#{__MODULE__}\" received event #{inspect(event_name)}")

        :persistent_term.get(:event_handlers)
        |> Map.get(event_name, [])
        |> Enum.each(fn handler -> apply(__MODULE__, handler, [data]) end)

        {:noreply, state}
      end
    end
  end

  defmacro listen(event_name, do: block) do
    block =
      quote do
        unquote(block)
        :ok
      end

    block = Macro.escape(block, unqote: true)

    quote bind_quoted: [event_name: event_name, block: block] do
      existing_handlers = :persistent_term.get(:event_handlers)

      handler_id =
        existing_handlers
        |> Map.get(event_name, [])
        |> length()

      name = :"#{Atom.to_string(event_name)}#{Integer.to_string(handler_id)}"

      updated_handlers =
        :persistent_term.get(:event_handlers)
        |> Map.update(event_name, [name], fn handlers ->
          [name | handlers]
        end)

      :persistent_term.put(:event_handlers, updated_handlers)

      def unquote(name)(data), do: unquote(block)
    end
  end
end
