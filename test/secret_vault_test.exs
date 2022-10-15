defmodule SecretVaultTest do
  use ExUnit.Case, async: true

  alias SecretVault.{Config, FSResolver}

  test "you can reed a secret after you've written it" do
    config = Config.new(:secret_vault)
    key = "test key"
    environment = "#{Mix.env()}"
    name = "secret_name_#{Enum.random(0..1000)}"
    data = "test data"

    on_exit(fn ->
      path_for_file_with_secret =
        FSResolver.resolve_file_path(
          config,
          environment,
          name
        )

      File.rm!(path_for_file_with_secret)
    end)

    assert :ok = SecretVault.put_secret(config, key, environment, name, data)

    assert {:ok, read} =
             SecretVault.fetch_secret(config, key, environment, name)

    assert read == data
  end
end
