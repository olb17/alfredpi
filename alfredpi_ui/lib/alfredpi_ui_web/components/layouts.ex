defmodule AlfredpiUiWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AlfredpiUiWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_menu, :atom, required: true, doc: "the current menu item"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="navbar bg-base-100 shadow-sm">
      <div class="navbar-start">
        <div class="dropdown">
          <div tabindex="0" role="button" class="btn btn-ghost lg:hidden">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 6h16M4 12h8m-8 6h16"
              />
            </svg>
          </div>
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content bg-base-100 rounded-box z-1 mt-3 w-52 p-2 shadow"
          >
            <.menu_entry
              menu={:tests}
              current_menu={@current_menu}
              label={gettext("Tests")}
              url={~p"/"}
            />
            <.menu_entry
              menu={:applications}
              current_menu={@current_menu}
              label={gettext("Applications")}
              url={~p"/apps"}
            />
            <.menu_entry
              menu={:choregraphy}
              current_menu={@current_menu}
              label={gettext("Choregraphies")}
              url={~p"/choregraphy"}
            />
            <.menu_entry
              menu={:configuration}
              current_menu={@current_menu}
              label={gettext("Configuration")}
              url={~p"/config"}
            />
            <.menu_entry
              menu={:swagger}
              current_menu={@current_menu}
              label={gettext("API Swagger")}
              url={~p"/swaggerui"}
            />
          </ul>
        </div>
        <a class="btn btn-ghost text-xl">Alfredpi</a>
      </div>
      <div class="navbar-center hidden lg:flex">
        <ul class="menu menu-horizontal px-1">
          <.menu_entry
            menu={:tests}
            current_menu={@current_menu}
            label={gettext("Tests")}
            url={~p"/"}
          />
          <.menu_entry
            menu={:applications}
            current_menu={@current_menu}
            label={gettext("Applications")}
            url={~p"/apps"}
          />
          <.menu_entry
            menu={:choregraphy}
            current_menu={@current_menu}
            label={gettext("Choregraphies")}
            url={~p"/choregraphy"}
          />
          <.menu_entry
            menu={:configuration}
            current_menu={@current_menu}
            label={gettext("Configuration")}
            url={~p"/config"}
          />
          <.menu_entry
            menu={:swagger}
            current_menu={@current_menu}
            label={gettext("API Swagger")}
            url={~p"/swaggerui"}
          />
        </ul>
      </div>
      <div class="navbar-end">
        <Layouts.theme_toggle />
      </div>
    </div>

    <main
      class="p-4 md:py-20 sm:px-6 lg:px-8 bg-base-300/50 transition-all duration-500 opacity-0 phx-page-loading:opacity-0"
      phx-mounted={JS.remove_class("opacity-0")}
    >
      <div class="mx-auto max-w-4xl">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  attr :current_menu, :atom, required: true, doc: "the current menu item"
  attr :menu, :atom, required: true, doc: "the menu item id"
  attr :label, :string, required: true, doc: "the menu item label"
  attr :url, :string, required: true, doc: "the menu item url"

  defp menu_entry(assigns) do
    ~H"""
    <li>
      <.link navigate={@url} class={if @current_menu == @menu, do: "menu-active"}>
        {@label}
      </.link>
    </li>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
