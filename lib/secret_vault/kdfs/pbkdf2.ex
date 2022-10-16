defmodule SecretVault.KDFs.PBKDF2 do
  @moduledoc """
  PKCS #2 PBKDF2 (Password-Based Key Derivation Function 2).

  Implements `SecretVault.KeyDerivation`.
  """

  @behaviour SecretVault.KeyDerivation

  @default_key_length 32
  @default_iterations_count 5

  @type option ::
          {:key_length, pos_integer()}
          | {:iterations_count, pos_integer()}

  @doc """
  Call the PBKDF function.

  ## Options

  - `:key_length` - set the key length (default is 32);
  - `:iterations_count` - set the count of iterations (default is 5).
  """
  @spec kdf(binary(), [option()]) :: binary()
  def kdf(user_input, opts) do
    key_length = Keyword.get(opts, :key_length, @default_key_length)

    iterations_count =
      Keyword.get(opts, :iterations_count, @default_iterations_count)

    salt = ""

    do_kdf(user_input, salt, iterations_count, key_length)
  end

  cond do
    Code.ensure_loaded?(:crypto) && function_exported?(:crypto, :pbkdf2_hmac, 5) ->
      # Note: This function is only available since OTP 24.2.
      defp do_kdf(user_input, salt, iterations_count, key_length) do
        :crypto.pbkdf2_hmac(
          :sha512,
          user_input,
          salt,
          iterations_count,
          key_length
        )
      end

    Code.ensure_loaded?(Pbkdf2KeyDerivation) &&
        function_exported?(Pbkdf2KeyDerivation, :pbkdf2!, 5) ->
      defp do_kdf(user_input, salt, iterations_count, key_length) do
        Pbkdf2KeyDerivation.pbkdf2!(
          user_input,
          salt,
          :sha512,
          iterations_count,
          key_length
        )
      end

    true ->
      raise CompileError,
        description:
          "It seems your OTP version is under 24.2 and you didn't " <>
            "install :pbkdf2_key_derivation library"
  end
end
