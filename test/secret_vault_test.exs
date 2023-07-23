defmodule SecretVaultTest do
  use ExUnit.Case, async: true
  doctest SecretVault, import: true

  alias SecretVault.Config

  test "you can reed a secret after you've written it" do
    password = "password"
    config = Config.new(:secret_vault, password: password)
    name = "secret_name_#{Enum.random(0..1000)}"
    data = "test data"

    on_exit(fn -> File.rm_rf!(SecretVault.resolve_environment_path(config)) end)

    assert :ok = SecretVault.put(config, name, data)

    assert {:ok, read} = SecretVault.fetch(config, name)

    assert read == data
  end

  describe "Testing in mix" do
    setup do
      project =
        MixTester.setup(
          name: "my_project",
          application_env: %{
            "config" => %{
              {:my_project, :secret_vault} => [default: [password: "password"]]
            }
          },
          project: [
            deps: [secret_vault: [path: File.cwd!()]]
          ]
        )

      on_exit(fn -> MixTester.cleanup(project) end)

      MixTester.write_ast(
        project,
        "test/my_project_test.exs",
        quote do
          defmodule MyProjectTest do
            use ExUnit.Case

            test "secret works" do
              {:ok, config} =
                SecretVault.Config.fetch_from_current_env(:my_project)

              SecretVault.Storage.to_application_env(config, :my_project)

              assert Application.get_env(:my_project, :secret_storage) == %{
                       "x" => "secret"
                     }
            end
          end
        end
      )

      MixTester.sh(project, "mkdir priv")

      {:ok, project: project}
    end

    test "Hidden files ignored", %{project: project} do
      MixTester.mix_cmd(project, "scr.insert", ["test", "x", "secret"])
      assert {_, 0} = MixTester.mix_cmd(project, "test")
    end
  end
end
