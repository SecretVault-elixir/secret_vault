defmodule SecretVault.ErrorFormatter do
  @moduledoc false
  # Manages rendering errors in CLI

  def format({:unknown_prefix, prefix, environment}) do
    "Prefix #{inspect(prefix)} for environment #{inspect(environment)}" <>
      " does not exist"
  end

  def format({:secret_already_exists, name}) do
    "Secret with name #{name} already exists"
  end

  def format({:secret_not_found, name, environment}) do
    "Secret #{name} not found in environment #{inspect(environment)}"
  end

  def format({:no_configuration_for_prefix, prefix}) do
    "No configuration for prefix #{inspect(prefix)} found"
  end

  def format({:no_configuration_for_app, otp_app}) do
    "No configuration for otp_app #{otp_app} found"
  end

  def format({:non_zero_exit_code, code, message}) do
    "Non zero exit code #{code}: #{message}"
  end

  def format({:executable_not_found, editor}) do
    "Editor not found: #{editor}"
  end

  def format(:invalid_encryption_key) do
    "Invalid key. It seems the secret was encrypted with " <>
      "a different encryption key"
  end
end
