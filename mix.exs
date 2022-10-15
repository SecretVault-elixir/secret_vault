defmodule SecretVault.MixProject do
  use Mix.Project

  # Change the version later
  @version "1.0.0"
  @source "https://github.com/spawnfest/secret_vault"

  def project do
    [
      app: :secret_vault,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Pathex",
      source_url: @source,
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end

  defp description do
    "Secret management inside your repository"
  end

  defp package do
    [
      description: description(),
      licenses: ["BSD 2-Clause"],
      files: [
        "lib",
        "mix.exs",
        "README.md",
        ".formatter.exs"
      ],
      maintainers: [
        "hissssst",
        "yunmikun2"
      ],
      links: %{
        GitHub: @source,
        Changelog: "#{@source}/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "readme"

      # TODO
      # extra_section: "GUIDES",
      # extras: ["README.md" | Path.wildcard("guides/*/*")] ++ ["CHANGELOG.md"],

      # groups_for_modules: groups_for_modules(),
      # groups_for_extras: groups_for_extras()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      # Type checking
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:gradient, github: "esl/gradient", only: :dev, runtime: false},

      # Linting
      {:mix_unused, "~> 0.4", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: :dev, runtime: false},

      # Documentation
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},

      # PBKDF
      {:pbkdf2_key_derivation, "~> 2.0", optional: true}
    ]
  end

  defp dialyzer do
    [plt_add_apps: [:mix]]
  end
end
