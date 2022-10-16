defmodule SecretVault.Storage do
  @moduledoc """
  Module with helpers to store secrets in various storages.

  ## Transform function

  All functions in this module accept an optional argument:
  [`transform`](`t:transform_function/0`) which is a function to
  transform secret values. This may be helpful if your storage doesn't
  support string keys (or may be you don't want to deal with them) or
  if you just want to transform the data somehow.
  """

  alias SecretVault.Config

  @typedoc """
  A function that transforms values fetched from the secret vault.
  """
  @type transform_function ::
          (String.t(), String.t() -> {a :: term(), b :: term()})

  @doc """
  Stores secrets in a `:persistent_term`.

  Stored secrets can be accessed with `:persistent_term.get(name)`

  ## Example

      iex> config = SecretVault.Config.test_config()
      iex> SecretVault.put(config, "name", "value")
      iex> to_persistent_term(config)
      iex> :persistent_term.get("name")
      "value"
  """
  def to_persistent_term(%Config{} = config, transform \\ &no_transform/2)
      when is_function(transform, 2) do
    at_key_value(config, transform, fn {key, value} ->
      :persistent_term.put(key, value)
    end)
  end

  @doc """
  Stores secrets in a `:ets` table using `:ets.insert`.

  Stored secrets can be accessed with `:ets.lookup(table, name)` or
  other `:ets` functions.

  ## Example

      iex> config = SecretVault.Config.test_config()
      iex> SecretVault.put(config, "name", "value")
      iex> table = :ets.new(:example_table, [:set, :protected])
      iex> to_ets(config, table)
      iex> :ets.lookup(table, "name")
      [{"name", "value"}]
  """
  def to_ets(config, table, transform \\ &no_transform/2)
      when is_function(transform, 2) do
    at_key_value(config, transform, &:ets.insert(table, &1))
  end

  @doc """
  Stores secrets in a `Application` env using `Application.put_env/4`.

  Stored secrets can be accessed with
  `Application.fetch_env!(application_name, :secret_storage)[name]`.

  ## Example

      iex> config = SecretVault.Config.test_config()
      iex> SecretVault.put(config, "name", "value")
      iex> to_application_env(config, :secret_vault)
      iex> Application.fetch_env!(:secret_vault, :secret_storage)["name"]
      "value"
  """
  def to_application_env(
        config,
        application_name,
        env_key \\ :secret_storage,
        transform \\ &no_transform/2
      )
      when is_function(transform, 2) do
    with {:ok, map} <- SecretVault.fetch_all(config) do
      map = Map.new(map, fn {key, value} -> transform.(key, value) end)
      Application.put_env(application_name, env_key, map)
    end
  end

  @doc """
  Stores secrets in a `Application` env using `Process.put/2`.

  Stored secrets can be accessed with `Process.get(name)`

  ## Example

      iex> config = SecretVault.Config.test_config()
      iex> SecretVault.put(config, "name", "value")
      iex> to_proccess_dictionary(config)
      iex> Process.get("name")
      "value"
  """
  def to_proccess_dictionary(config, transform \\ &no_transform/2)
      when is_function(transform, 2) do
    at_key_value(config, transform, fn {key, value} ->
      Process.put(key, value)
    end)
  end

  defp no_transform(key, value) do
    {key, value}
  end

  defp at_key_value(config, transform, closure) do
    with {:ok, map} <- SecretVault.fetch_all(config) do
      Enum.each(map, fn {key, value} ->
        entry = transform.(key, value)
        closure.(entry)
      end)
    end
  end
end
