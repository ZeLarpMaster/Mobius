# Mock the API response before Mobius is started
app_info = %{
  "shards" => 1,
  "url" => "wss://gateway.discord.gg",
  "session_start_limit" => %{"remaining" => 1000}
}

url = Mobius.Rest.Client.base_url() <> "/gateway/bot"
Tesla.Mock.mock_global(fn %{url: ^url, method: :get} -> Mobius.Fixtures.json(app_info) end)

Application.ensure_all_started(:mobius)

ExUnit.start(capture_log: true)
