defmodule Mobius.Core.HeartbeatInfo do
  @moduledoc false

  defstruct [:ping, :send_stamp, :ack_stamp]

  @type t :: %__MODULE__{
          ping: non_neg_integer(),
          send_stamp: integer | nil,
          ack_stamp: integer | nil
        }

  @spec new :: t()
  def new do
    %__MODULE__{
      ping: 0,
      send_stamp: nil,
      ack_stamp: time()
    }
  end

  @spec received_ack(t()) :: t()
  # Ignore acks received before sending
  def received_ack(%__MODULE__{send_stamp: nil} = info), do: info
  def received_ack(info), do: info |> set_ack() |> update_ping() |> reset_send()

  @spec sending(t()) :: t()
  def sending(info), do: info |> reset_ack() |> set_send()

  @spec can_send?(t()) :: boolean
  def can_send?(%__MODULE__{ack_stamp: ack}), do: ack != nil

  @spec get_ping(t()) :: non_neg_integer
  def get_ping(%__MODULE__{ping: ping}), do: ping

  defp set_ack(info), do: %__MODULE__{info | ack_stamp: time()}
  defp reset_ack(info), do: %__MODULE__{info | ack_stamp: nil}

  defp set_send(info), do: %__MODULE__{info | send_stamp: time()}
  defp reset_send(info), do: %__MODULE__{info | send_stamp: nil}

  defp update_ping(info), do: %__MODULE__{info | ping: info.ack_stamp - info.send_stamp}

  defp time, do: System.monotonic_time(:millisecond)
end
