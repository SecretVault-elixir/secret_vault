priv = to_string :code.priv_dir :secret_vault
File.mkdir_p priv
ExUnit.start()
File.rm_rf! priv
