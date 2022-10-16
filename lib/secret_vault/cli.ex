defmodule SecretVault.CLI do
  @moduledoc false
  # This module is a set of helpers for tasks

  @spec find_option([String.t()], String.t() | nil, String.t()) ::
          String.t() | nil
  def find_option(args, short, option)

  def find_option(["--" <> option, value | _rest], _short, option)
      when is_binary(option) do
    value
  end

  def find_option(["-" <> short, value | _rest], short, _option)
      when is_binary(short) do
    value
  end

  def find_option(["--" <> flag | rest], short, option)
      when is_binary(option) do
    case String.split(flag, "=") do
      [^option, value] ->
        value

      _ ->
        find_option(rest, short, option)
    end
  end

  def find_option([_ | rest], short, option) do
    find_option(rest, short, option)
  end

  def find_option([], _, _) do
    nil
  end
end
