defmodule SecretVault.Cipher do
  @moduledoc """
  Provides an interface to implement encryption methods.

  See `SecretVault.Cipher.ErlangCrypto` implementation for more
  details.
  """

  @typedoc """
  A key for symetric encryption algorithm as a binary.
  """
  @type key :: binary()

  @typedoc """
  Binary blob that contains encrypted data.
  """
  @type cypher_text :: binary()

  @typedoc """
  Binary blob that contains decrypted data.
  """
  @type plain_text :: binary()

  @doc """
  Encrypt the `plain_text` with the `key`.
  """
  @callback encrypt(key, plain_text, opts) :: cypher_text
            when opts: Keyword.t()

  @doc """
  Decrypt the `cypher_text` with the `key` used to get it.

  If key is invalid, `:invalid_key` error is returned. If
  inappropriate text is passed as `cypher_text`, `Cipher.Error` is
  raised.
  """
  @callback decrypt(key, cypher_text, opts) ::
              {:ok, plain_text} | {:error, :invalid_encryption_key}
            when opts: Keyword.t()

  defmodule Error do
    @moduledoc """
    This exception gets raised when some error occurs during decoding.
    """
    defexception [:message]
  end

  @doc """
  Serialize encryption metadata end a ciphertext into a single binary.

  This is a helper function to prepare the data to be written on the
  disk.

  ## Example

      iex> cipher = "MyNewCipher"
      ...> algorithm = "default"
      ...> ciphertext = "testtest"
      ...> SecretVault.Cipher.pack(cipher, algorithm, [ciphertext])
      "MyNewCipher;default;7465737474657374"
  """
  @spec pack(cipher, algorithm, [property]) :: binary
        when cipher: String.t(), algorithm: String.t(), property: binary
  def pack(cipher, algorithm, properties)
      when is_binary(cipher) and is_binary(algorithm) and is_list(properties) do
    encoded_properties = Enum.map(properties, &Base.encode16/1)
    Enum.join([cipher, algorithm | encoded_properties], ";")
  end

  @doc """
  Deserialize `pack/3`'ed data.

  ## Example

      iex> cipher = "MyNewCipher"
      iex> serialized = "MyNewCipher;default;7465737474657374"
      iex> SecretVault.Cipher.unpack!(cipher, serialized)
      ["default", "testtest"]
  """
  @spec unpack!(cipher, binary) :: [property]
        when cipher: String.t(), property: binary
  def unpack!(cipher, binary)
      when is_binary(cipher) and is_binary(binary) do
    case String.split(binary, ";") do
      [^cipher, algorithm | properties] ->
        properties = Enum.map(properties, &Base.decode16!/1)
        [algorithm | properties]

      [other_cipher | _] ->
        raise Error, "Wrong cipher!. Expected #{cipher}, got: #{other_cipher}"
    end
  end
end
