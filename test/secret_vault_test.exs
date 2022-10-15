defmodule SecretVaultTest do
  use ExUnit.Case
  doctest SecretVault

  test "greets the world" do
    assert SecretVault.hello() == :world
  end
end
