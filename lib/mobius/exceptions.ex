defmodule Mobius.TimeoutError do
  defexception message: "Operation timed out"
end

defmodule Mobius.CancelledError do
  defexception message: "Operation cancelled"
end

defmodule Mobius.RatelimitError do
  defexception message: "Operation abandonned to prevent being ratelimited"
end
