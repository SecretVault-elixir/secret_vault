defmodule Mix.Tasks.Scr.Audit do
  @moduledoc """
  Performs audit of passwords to detect duplicates and weak passwords.
  Exits with 1 exit code if at least one check fails.

  ## Check options

  - `--no-similarity` - to disable password similarity check
  - `--digits` - to enforce passwords having at least one digit
  - `--uppercase` - to enforce uppercase letters in password
  - `--mix-length=N` - to enforce minimul length requirement

  ## Config override

  You can override config options by providing command line arguments.

  - `:cipher` - specify a cipher module to use;
  - `:priv_path` - path to `priv` directory;
  - `:prefix` - prefix to use (defaults to `default`);
  - `:password` - use a password that's different from the one that's
    configured.
  """

  @shortdoc "Performs audit of passwords"
  @requirements ["app.config"]

  use Mix.Task

  require Config
  alias Elixir.Config.Reader
  alias SecretVault.{CLI, Config}

  @spec run([String.t()]) :: no_return()
  def run(args) do
    otp_app = Mix.Project.config()[:app]

    config_file =
      Enum.find(Mix.Project.config_files(), fn file ->
        String.ends_with?(file, "/config.exs")
      end) ||
        raise "No config.exs found"

    envs = ~w[prod test dev]a

    config_opts =
      Config.available_options()
      |> Enum.map(&{&1, CLI.find_option(args, nil, "#{&1}")})
      |> Enum.reject(fn {_, value} -> is_nil(value) end)
      |> Keyword.put_new(:priv_path, CLI.priv_path())

    Enum.flat_map(envs, fn env ->
      # Mix.env(env)
      Reader.read!(config_file, env: env)

      otp_app
      |> Application.get_env(:secret_vault, [])
      |> Enum.flat_map(fn {prefix, _} ->
        prefix = to_string(prefix)

        {:ok, config} =
          Config.fetch_from_env(otp_app, "#{env}", prefix, config_opts)

        do_fetch(config)
      end)
    end)
    |> check(args)

    System.halt(Process.get(:status, 0))
  end

  defp do_fetch(config) do
    case SecretVault.fetch_all(config) do
      {:ok, secrets} ->
        for {name, value} <- secrets do
          {config, name, value}
        end

      {:error, {:unknown_prefix, _, _}} ->
        []
    end
  end

  defp check(secrets, args) do
    plaintext_check(secrets)

    unless "--no-similarity" in args do
      similarity_check(secrets)
    end

    if "--digits" in args do
      digits_check(secrets)
    end

    if "--uppercase" in args do
      uppercase_check(secrets)
    end

    len = CLI.find_option(args, "l", "min-length") || "16"
    length_check(secrets, String.to_integer(len))
  end

  defp plaintext_check(secrets) do
    Enum.each(secrets, fn {config, _, _} = secret ->
      if config.cipher == SecretVault.Cipher.Plaintext do
        Mix.shell().error("#{pathify(secret)} contains plaintext password")
        Process.put(:status, 1)
      end
    end)
  end

  defp uppercase_check(secrets) do
    Enum.each(secrets, fn {_, _, value} = secret ->
      unless value =~ ~r/[A-Z]/ do
        Mix.shell().error(
          "#{pathify(secret)} does not contain uppercase symbols"
        )

        Process.put(:status, 1)
      end
    end)
  end

  defp length_check(secrets, len) do
    Enum.each(secrets, fn {_, _, value} = secret ->
      if byte_size(value) < len do
        Mix.shell().error("#{pathify(secret)} is too short")
        Process.put(:status, 1)
      end
    end)
  end

  defp digits_check(secrets) do
    Enum.each(secrets, fn {_, _, value} = secret ->
      unless value =~ ~r/\d/ do
        Mix.shell().error("#{pathify(secret)} does not contain digits")
        Process.put(:status, 1)
      end
    end)
  end

  defp similarity_check([{_, _, left_value} = left | rest]) do
    Enum.each(rest, fn {_, _, right_value} = right ->
      if String.jaro_distance(left_value, right_value) > 0.5 do
        Mix.shell().error(
          "#{pathify(right)} and #{pathify(left)} secrets are too similar"
        )

        Process.put(:status, 1)
      end
    end)

    similarity_check(rest)
  end

  defp similarity_check([]) do
    []
  end

  defp pathify({config, name, _}) do
    path = SecretVault.resolve_secret_path(config, name)

    case File.cwd() do
      {:ok, cwd} -> Path.relative_to(path, cwd)
      _ -> path
    end
  end
end
