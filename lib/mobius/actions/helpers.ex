defmodule Mobius.Actions.Helpers do
  @moduledoc false

  @doc "Generates the usage caution for get_cached_*'s documentation"
  @spec cache_caution(String.t()) :: String.t()
  def cache_caution(refer_to) do
    """
    ## Usage Caution
    When using this function, please keep in mind the caches aren't perfect.
    As stated in the
    [Discord documentation](https://discord.com/developers/docs/reference#consistency),
    events may never be sent to a client (this library).
    This means the cache may not contain everything you expect it to
    or may be out of date if an update event isn't sent (or received).

    If being up to date is very important to you,
    you may request up to date information with `#{refer_to}`
    """
  end
end
