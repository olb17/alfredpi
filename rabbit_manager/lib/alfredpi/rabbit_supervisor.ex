defmodule Alfredpi.RabbitSupervisor do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Supervisor

  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(args) do
    Logger.debug("[Rabbit Supervisor] Starting")

    chor_dir =
      Keyword.get(
        args,
        :choregraphy_dir,
        Path.join(Application.fetch_env!(:rabbit_manager, :dir), "choregraphy")
      )

    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Alfredpi.DynamicSupervisor},
      {Phoenix.PubSub, name: RabbitManager.PubSub},
      Alfredpi.ChoregraphyAgent,
      {Alfredpi.ChoregraphyManager, chor_dir},
      Alfredpi.RabbitManager
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
