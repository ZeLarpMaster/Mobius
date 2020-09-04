defmodule Mobius.Core.SocketCodes do
  @moduledoc false

  @type resume_options :: :resume | :dont_resume | :dont_reconnect
  @type properties :: {String.t(), resume_options()}

  @codes %{
    1000 => {"Normal", :resume},
    1001 => {"Going away", :resume},
    4000 => {"Unknown error", :resume},
    4001 => {"Unknown opcode", :dont_resume},
    4002 => {"Decode error", :resume},
    4003 => {"Not authenticated", :dont_resume},
    4004 => {"Authentication failed", :dont_reconnect},
    4005 => {"Already authenticated", :dont_resume},
    4007 => {"Invalid seq", :dont_resume},
    4008 => {"Rate limited", :resume},
    4009 => {"Session timed out", :dont_resume},
    4010 => {"Invalid shard", :dont_reconnect},
    4011 => {"Sharding required", :dont_reconnect},
    4012 => {"Invalid API version", :dont_reconnect},
    4013 => {"Invalid intent(s)", :dont_reconnect},
    4014 => {"Disallowed intent(s)", :dont_reconnect}
  }

  @spec translate_close_code(integer) :: properties()

  for {close_code, properties} <- @codes do
    def translate_close_code(unquote(close_code)), do: unquote(properties)
  end

  # If the code is unknown, attempt to resume
  def translate_close_code(_), do: {"", :resume}
end
