defmodule AlfredpiUi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  use Gettext, backend: AlfredpiUiWeb.Gettext

  @impl true
  def start(_type, _args) do
    children =
      children(target()) ++
        [
          AlfredpiUiWeb.Telemetry,
          {DNSCluster, query: Application.get_env(:alfredpi_ui, :dns_cluster_query) || :ignore},
          {Phoenix.PubSub, name: AlfredpiUi.PubSub},
          # Start a worker by calling: AlfredpiUi.Worker.start_link(arg)
          # {AlfredpiUi.Worker, arg},
          # Start to serve requests, typically the last entry
          AlfredpiUiWeb.Endpoint,
          {Task,
           fn ->
             Process.sleep(2_000)

             Gettext.put_locale(
               Alfredpi.RabbitManager.get_parameters()
               |> Map.get(:language)
               |> to_string()
             )
           end}
        ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlfredpiUi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def children(:host) do
    [Alfredpi.RabbitSupervisor]
  end

  def children(_target), do: []

  def target() do
    Application.get_env(:rabbit_manager, :target)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AlfredpiUiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
