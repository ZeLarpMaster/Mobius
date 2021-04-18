defmodule Mobius.Core.Cog do
  @moduledoc false

  @enforce_keys [:name, :module, :description, :commands]
  defstruct [:name, :module, :description, :commands]

  @type t :: %__MODULE__{
          module: module(),
          name: String.t(),
          description: String.t() | false | nil,
          commands: Command.processed()
        }
end
