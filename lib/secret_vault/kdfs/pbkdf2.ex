defmodule SecretVault.KDFs.PBKDF2 do
  @moduledoc """
  PKCS #2 PBKDF2 (Password-Based Key Derivation Function 2).

  Implements `SecretVault.KeyDerivation`.
  """

  @behaviour SecretVault.KeyDerivation

  @default_key_length 32
  @default_iterations_count 5

  @doc """
  Call the PBKDF function.

  ## Options

  - `:key_length` - set the key length (default is 32);
  - `:iterations_count` - set the count of iterations (default is 5).
  """
  def kdf(user_input, opts) do
    key_length = Keyword.get(opts, :key_length, @default_key_length)
    iterations_count = Keyword.get(opts, :iterations_count, @default_iterations_count)
    salt = ""

    cond do
      function_exported?(:crypto, :pbkdf2_hmac, 5) ->
        # Note: This function is only available since OTP 24.2.
        # credo:disable-for-next-line Credo.Check.Refactor.Apply
        apply(:crypto, :pbkdf2_hmac, [
          :sha512,
          user_input,
          salt,
          iterations_count,
          key_length
        ])

      function_exported?(Pbkdf2KeyDerivation, :pbkdf2!, 5) ->
        # credo:disable-for-next-line Credo.Check.Refactor.Apply
        apply(Pbkdf2KeyDerivation, :pbkdf2!, [
          user_input,
          salt,
          :sha512,
          iterations_count,
          key_length
        ])

      true ->
        raise "It seems your OTP version is under 24.2 and you didn't " <>
                "install :pbkdf2_key_derivation library"
    end
  end
end
