defmodule AlfredpiUiWeb.LiveviewGettext do
  use Gettext, backend: AlfredpiUiWeb.Gettext

  def on_mount(_, _params, _session, socket) do
    Alfredpi.RabbitManager.get_parameters()
    |> Map.fetch!(:language)
    |> to_string()
    |> dbg
    |> Gettext.put_locale()

    {:cont, socket}
  end
end
