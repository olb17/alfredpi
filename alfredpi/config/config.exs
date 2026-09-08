# This file is responsible for configuring your application and its
# dependencies.
#
# This configuration file is loaded before any dependency and is restricted to
# this project.
import Config

# Enable the Nerves integration with Mix
Application.start(:nerves_bootstrap)

config :alfredpi, target: Mix.target()
config :rabbit_manager, target: Mix.target()

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Configures the endpoint
config :alfredpi_ui, AlfredpiUiWeb.Endpoint,
  url: [host: "alfredpi.local"],
  secret_key_base: "24rUGOxQZcRmS5/Ikmkcn5J8BnsewlStHva1fkGP2PljqXY863/bRF1uPw8cnSyc",
  http: [port: 80],
  server: true,
  check_origin: false,
  adapter: Bandit.PhoenixAdapter,
  cache_static_manifest: "priv/static/cache_manifest.json",
  render_errors: [
    formats: [html: AlfredpiUiWeb.ErrorHTML, json: AlfredpiUiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AlfredpiUi.PubSub,
  code_reloader: false,
  debug_errors: false,
  live_view: [signing_salt: "S7rT7aTJ"]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1745048856"

if Mix.target() == :host do
  import_config "host.exs"
else
  import_config "target.exs"
end
