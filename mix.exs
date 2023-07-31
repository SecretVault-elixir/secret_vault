defmodule SecretVault.MixProject do
  use Mix.Project

  @version "1.2.1"
  @source "https://github.com/SecretVault-elixir/secret_vault"

  def project do
    [
      app: :secret_vault,
      name: "SecretVault",
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: @source,
      homepage_url: @source,
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end

  defp description do
    "All-included solution for managing secrets in mix projects"
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
      main: "readme",

      # TODO
      # extra_section: "GUIDES",
      extra_section: "GUIDES",
      extras: ["README.md" | Path.wildcard("guides/*/*")] ++ ["CHANGELOG.md"],
      groups_for_modules: groups_for_modules(),
      groups_for_extras: groups_for_extras()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      # Testing mix tasks
      {:mix_tester, "~> 1.0", only: :test},

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
    [
      plt_add_apps: [:mix]
    ]
  end

  defp groups_for_extras do
    [
      Tutorials: ~r/guides\/tutorials\/.*/
    ]
  end

  defp groups_for_modules do
    [
      Runtime: [
        SecretVault,
        SecretVault.Config,
        SecretVault.Storage
      ],
      Development: [
        Mix.Tasks.Scr.Create,
        Mix.Tasks.Scr.Edit,
        Mix.Tasks.Scr.Show,
        Mix.Tasks.Scr.Audit,
        Mix.Tasks.Scr.Insert
      ],
      Ciphers: [
        SecretVault.Cipher,
        SecretVault.Cipher.ErlangCrypto,
        SecretVault.Cipher.Plaintext
      ],
      "Key Derivation": [
        SecretVault.KeyDerivation,
        SecretVault.KDFs.PBKDF2
      ]
    ]
  end
end
