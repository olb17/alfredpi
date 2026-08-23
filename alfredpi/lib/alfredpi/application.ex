defmodule Alfredpi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        Alfredpi.RabbitSupervisor
        # Children for all targets
        # Starts a worker by calling: Alfredpi.Worker.start_link(arg)
        # {Alfredpi.Worker, arg},
      ] ++ target_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Alfredpi.Supervisor]

    if not VintageNetWizard.wifi_configured?("wlan0") do
      Application.stop(:alfredpi_ui)

      VintageNetWizard.run_wizard(
        on_exit: {Alfredpi.Application, :exit_ap_mode, []},
        device_info: get_device_info()
      )
    end

    Supervisor.start_link(children, opts)
  end

  def exit_ap_mode() do
    # Stop the application and exit AP mode
    Alfredpi.RabbitManager.leds_color("#000000", :all)
    :ok = Application.start(:alfredpi_ui)
  end

  # List all child processes to be supervised
  if Mix.target() == :host do
    defp target_children() do
      [
        # Children that only run on the host during development or test.
        # In general, prefer using `config/host.exs` for differences.
        #
        # Starts a worker by calling: Host.Worker.start_link(arg)
        # {Host.Worker, arg},
      ]
    end
  else
    defp target_children() do
      gpio_pin = Application.get_env(:wizard_example, :gpio_pin, 17)

      [
        Alfredpi.SoundMonitor,
        {Alfredpi.SSIDWizard.Button, gpio_pin},
        Rainbow.Worker,
        Alfredpi.Ear,
        {Task,
         fn ->
           Alfredpi.RabbitManager.platform_ready()
         end}
      ]
    end
  end

  defp serial_number() do
    with boardid_path when not is_nil(boardid_path) <- System.find_executable("boardid"),
         {id, 0} <- System.cmd(boardid_path, []) do
      String.trim(id)
    else
      _other -> "Unknown"
    end
  end

  defp kv_to_map(key_values) do
    for kv <- key_values, into: %{}, do: kv
  end

  def get_device_info() do
    kv =
      Nerves.Runtime.KV.get_all_active()
      |> kv_to_map

    mac_addr = VintageNet.get(["interface", "wlan0", "mac_address"])

    [
      {"WiFi Address", mac_addr},
      {"Serial number", serial_number()},
      {"Firmware", kv["nerves_fw_product"]},
      {"Firmware version", kv["nerves_fw_version"]},
      {"Firmware UUID", kv["nerves_fw_uuid"]}
    ]
  end
end
