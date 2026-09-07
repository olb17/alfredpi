defmodule Alfredpi.MixProject do
  use Mix.Project

  @app :alfredpi
  @version "0.1.0"
  @all_targets [
    :alfredpi_rpi3a
  ]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.18",
      archives: [nerves_bootstrap: "~> 1.13"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [{@app, release()}]
    ]
  end

  def cli do
    [preferred_targets: [run: :host, test: :host]]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools, :inets],
      mod: {Alfredpi.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.10", runtime: false},
      {:shoehorn, "~> 0.9.1"},
      {:ring_logger, "~> 0.11.0"},
      {:toolshed, "~> 0.5.0"},

      # Allow Nerves.Runtime on host to support development, testing and CI.
      # See config/host.exs for usage.
      {:nerves_runtime, "~> 0.13.0"},

      # Dependencies for all targets except :host
      {:nerves_pack, "~> 0.7.1", targets: @all_targets},
      {:observer_cli, "~> 2.0"},
      {:blinkchain,
       git: "https://github.com/valiot/blinkchain", submodules: "true", ref: "a10971c"},
      {:circuits_gpio, "~> 2.1"},
      {:vintage_net, "~> 0.13"},
      {:vintage_net_wifi, "~> 0.12"},
      {:vintage_net_wizard, "~> 0.4", targets: @all_targets, override: true},
      {:porcelain, "~> 2.0"},
      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
      # {:nerves_system_rpi3a, "~> 1.24", runtime: false, targets: :rpi3a}
      {:rabbit_manager, path: "../rabbit_manager"},
      {:alfredpi_ui, path: "../alfredpi_ui"},
      {:alfredpi_rpi3a, github: "olb17/alfredpi_rpi3a", runtime: false, targets: :alfredpi_rpi3a}
    ]
  end

  def release do
    [
      overwrite: true,
      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end
end
