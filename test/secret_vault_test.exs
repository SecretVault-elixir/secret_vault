defmodule SecretVaultTest do
  use ExUnit.Case, async: true
  doctest SecretVault, import: true

  alias SecretVault.Config

  test "you can reed a secret after you've written it" do
    password = "password"
    config = Config.new(:secret_vault, password: password)
    name = "secret_name_#{Enum.random(0..1000)}"
    data = "test data"

    on_exit(fn -> File.rm_rf!(SecretVault.resolve_environment_path(config)) end)

    assert :ok = SecretVault.put(config, name, data)

    assert {:ok, read} = SecretVault.fetch(config, name)

    assert read == data
  end
end
