defmodule SecretVault.KeyDerivation do
  @moduledoc """
  Defines an interface to derive a key from user-defined password.
  """

  @doc """
  Return binary derived from `user_input`.
  """
  @callback kdf(user_input, opts) :: binary()
            when user_input: String.t(),
                 opts: Keyword.t()
end
