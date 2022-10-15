defmodule SecretVault.KDFs.PBKDF2Test do
  use ExUnit.Case

  alias SecretVault.KDFs.PBKDF2

  test "subsequent applications return the same value" do
    input = "test"
    opts = [key_length: 16, iterations_count: 2]
    assert PBKDF2.kdf(input, opts) == PBKDF2.kdf(input, opts)
  end
end
