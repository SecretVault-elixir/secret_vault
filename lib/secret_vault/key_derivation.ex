defmodule SecretVault.KeyDerivation do
  @moduledoc """
  Provides a way to derive a key from a user input.
  """

  @doc """
  Return binary derived from `user_input`.
  """
  @callback kdf(user_input, opts) :: binary()
            when user_input: String.t(),
                 opts: Keyword.t()
end
