defmodule Alfredpi.AppMan.MixProject do
  use Mix.Project

  def project do
    [
      app: :rabbit_manager,
      version: "0.1.0",
      elixir: "~> 1.15",
      deps: deps(),
      preferred_cli_env: [
        "test.watch": :test
      ],
      compilers: [:leex, :yecc] ++ Mix.compilers()
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_pubsub, "~> 2.0"},
      {:ecto, "~> 3.10"},
      {:websockex, "~> 0.5.1"},
      {:jason, "~> 1.2"},
      {:req, "~> 0.7.3"},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test]}
    ]
  end
end
