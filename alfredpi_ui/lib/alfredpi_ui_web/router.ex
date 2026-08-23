defmodule AlfredpiUiWeb.Router do
  use AlfredpiUiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AlfredpiUiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: AlfredpiUiWeb.ApiSpec
  end

  scope "/" do
    pipe_through :browser
    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"

    live_session :default, on_mount: AlfredpiUiWeb.LiveviewGettext do
      # Mount the LiveView session with the sound file download mount
      scope "/", AlfredpiUiWeb do
        live "/", HomeLive, :home
        live "/apps", AppsLive, :index
        live "/choregraphy", ChoregraphyLive, :index
        live "/choregraphy/new", ChoregraphyLive, :new
        live "/choregraphy/:code", ChoregraphyLive, :edit
        live "/config", GeneralLive, :index

        get "/download-sound-file/:file", DownloadSoundFileController, :download
      end
    end
  end

  scope "/api" do
    pipe_through :api
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []

    scope "/", AlfredpiUiWeb do
      get "/choregraphies", ChoregraphyController, :index
      get "/choregraphies/:code/play", ChoregraphyController, :play
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:alfredpi_ui, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AlfredpiUiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
