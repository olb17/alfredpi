defmodule Alfredpi.ApplicationManagerTest do
  use ExUnit.Case, async: true

  alias Alfredpi.ApplicatonManager

  test "List available applications at startup from configuration" do
    app_list = ApplicationManager.get_applications()
    assert length(app_list) == 3, "Wrong application list count"
    assert Enum.all?(app_list, fn %name{} -> name == Alfredpi.EmbedApplication end)
  end

  test "Start and stop a unique application" do
    app_list = ApplicationManager.get_applications()
    app = hd(app_list)
    assert :stopped = app.state, "application #{inspect(app)} is not stopped at test beginning"

    assert :ok = ApplicationManager.start_application(app),
           "Cannot start application #{inspect(app)}"

    app_list = ApplicationManager.get_applications()
    assert :started = app.state, "application #{inspect(app)} is not started"
  end

  test "Start an application with resource and list available applications with activation status" do
    app_list = ApplicationManager.get_applications()
    sound_app = find_app(app_list, :sound_app)

    assert :ok = ApplicationManager.start_application(sound_app),
           "Cannot start application #{inspect(sound_app)}"

    app_list = ApplicationManager.get_applications()
    notif_app = find_app(app_list, :notif_app)
    sound_app2 = find_app(app_list, :sound_app2)
    assert :started = sound_app2.state, "application #{inspect(sound_app2)} is not started"
  end

  test "Cannot start an application with resource when the resource is already locked" do
    app_list = ApplicationManager.get_applications()
    sound_app = find_app(app_list, :sound_app)
    sound_app2 = find_app(app_list, :sound_app2)

    assert :ok = ApplicationManager.start_application(sound_app),
           "Cannot start application #{inspect(sound_app)}"

    assert :ok = ApplicationManager.start_application(sound_app2),
           "Can start application #{inspect(sound_app2)}"
  end

  test "Change application configuration and save it" do
    assert false, "Not implemented yet"
  end

  test "Application manager gets the event when an application dies or starts" do
    assert false, "Not implemented yet"
  end

  defp find_app(list, app), do: Enum.find(list, &(&1.id == app))
end
