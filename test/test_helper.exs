url = Mobius.Rest.Client.base_url() <> "/gateway/bot"
app_info = %{"shards" => 1, "url" => "wss://gateway.discord.gg"}
Tesla.Mock.mock_global(fn %{url: ^url, method: :get} -> Mobius.Fixtures.json(app_info) end)

Application.ensure_all_started(:mobius)

ExUnit.start()
