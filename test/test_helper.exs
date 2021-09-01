# Mock the API response before Mobius is started
Mobius.Fixtures.mock_gateway_bot()

Application.ensure_all_started(:mobius)

ExUnit.start(capture_log: true, exclude: [:skip])
