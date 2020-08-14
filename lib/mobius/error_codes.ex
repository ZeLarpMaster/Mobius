defmodule Mobius.ErrorCodes do
  @moduledoc false

  # The information in this module is based on
  # https://discord.com/developers/docs/topics/opcodes-and-status-codes

  # JSON error codes
  @json_errors %{
    0 => "General error",
    10001 => "Unknown account",
    10002 => "Unknown application",
    10003 => "Unknown channel",
    10004 => "Unknown guild",
    10005 => "Unknown integration",
    10006 => "Unknown invite",
    10007 => "Unknown member",
    10008 => "Unknown message",
    10009 => "Unknown permission overwrite",
    10010 => "Unknown provider",
    10011 => "Unknown role",
    10012 => "Unknown token",
    10013 => "Unknown user",
    10014 => "Unknown emoji",
    10015 => "Unknown webhook",
    10026 => "Unknown ban",
    10027 => "Unknown SKU",
    10028 => "Unknown Store Listing",
    10029 => "Unknown entitlement",
    10030 => "Unknown build",
    10031 => "Unknown lobby",
    10032 => "Unknown branch",
    10036 => "Unknown redistributable",
    20001 => "Bots cannot use this endpoint",
    20002 => "Only bots can use this endpoint",
    30001 => "Maximum number of guilds reached (100)",
    30002 => "Maximum number of friends reached (1000)",
    30003 => "Maximum number of pins reached for the channel (50)",
    30005 => "Maximum number of guild roles reached (250)",
    30007 => "Maximum number of webhooks reached (10)",
    30010 => "Maximum number of reactions reached (20)",
    30013 => "Maximum number of guild channels reached (500)",
    30015 => "Maximum number of attachments in a message reached (10)",
    30016 => "Maximum number of invites reached (1000)",
    40001 => "Unauthorized. Provide a valid token and try again",
    40002 => "You need to verify your account in order to perform this action",
    40005 => "Request entity too large",
    40006 => "This feature has been temporarily disabled server-side",
    40007 => "The user is banned from this guild",
    50001 => "Missing access",
    50002 => "Invalid account type",
    50003 => "Cannot execute action on a DM channel",
    50004 => "Guild widget disabled",
    50005 => "Cannot edit a message authored by another user",
    50006 => "Cannot send an empty message",
    50007 => "Cannot send messages to this user",
    50008 => "Cannot send messages in a voice channel",
    50009 => "Channel verification level is too high for you to gain access",
    50010 => "OAuth2 application does not have a bot",
    50011 => "OAuth2 application limit reached",
    50012 => "Invalid OAuth2 state",
    50013 => "You lack permissions to perform that action",
    50014 => "Invalid authentication token provided",
    50015 => "Note was too long",
    50016 => "Provided too few or too many messages to delete",
    50019 => "A message can only be pinned to the channel it was sent in",
    50020 => "Invite code was either invalid or taken",
    50021 => "Cannot execute action on a system message",
    50025 => "Invalid OAuth2 access token provided",
    50034 => "A message provided was too old to bulk delete",
    50035 => "Invalid form body or invalid Content-Type provided",
    50036 => "An invite was accepted to a guild the application's bot is not in",
    50041 => "Invalid API version provided",
    90001 => "Reaction was blocked",
    130_000 => "API resource is currently overloaded. Try again a little later"
  }

  @spec translate_json_error(integer) :: String.t()
  def translate_json_error(error_code) do
    Map.fetch!(@json_errors, error_code)
  end

  # Gateway error codes
  @gateway_errors %{
    1000 => "Normal closure",
    1001 => "Going away",
    4000 => "Unknown error",
    4001 => "Unknown opcode",
    4002 => "Decode error",
    4003 => "Not authenticated",
    4004 => "Authentication failed",
    4005 => "Already authenticated",
    4007 => "Invalid seq",
    4008 => "Rate limited",
    4009 => "Session timed out",
    4010 => "Invalid shard",
    4011 => "Sharding required",
    4012 => "Invalid API version",
    4013 => "Invalid intent(s)",
    4014 => "Disallowed intent(s)"
  }

  @gateway_can_resume_errors [1000, 1001, 4000, 4002, 4008]
  @gateway_cant_resume_errors [4001, 4003, 4005, 4007, 4009]
  @gateway_cant_reconnect_errors [4004, 4010, 4011, 4012, 4013, 4014]

  @spec translate_gateway_error(integer) :: {String.t(), :resume | :dont_resume | :dont_reconnect}
  def translate_gateway_error(error_code) do
    error = Map.get(@gateway_errors, error_code, "")

    cond do
      error_code in @gateway_cant_reconnect_errors -> {error, :dont_reconnect}
      error_code in @gateway_cant_resume_errors -> {error, :dont_resume}
      error_code in @gateway_can_resume_errors -> {error, :resume}
      # Shouldn't happen, but just in case, try to resume
      true -> {error, :resume}
    end
  end
end
