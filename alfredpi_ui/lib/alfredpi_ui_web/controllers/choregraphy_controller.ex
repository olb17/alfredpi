defmodule AlfredpiUiWeb.ChoregraphyController do
  use AlfredpiUiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema

  alias Alfredpi.ChoregraphyManager
  alias AlfredpiUiWeb.Schemas

  tags(["choregraphies"])

  operation(:index,
    summary: "List Choregraphies",
    parameters: [],
    request_body: {},
    responses: [
      ok: {"ChoregraphiesResponse response", "application/json", Schemas.ChoregraphiesResponse}
    ]
  )

  def index(conn, _params) do
    choregraphies = ChoregraphyManager.list_choregraphy()
    render(conn, :index, choregraphies: choregraphies)
  end

  operation(:play,
    summary: "Play Choregraphy",
    parameters: [
      code: [
        in: :path,
        type: %Schema{type: :string},
        description: "Choregraphy code",
        example: "CODE_1",
        required: true
      ]
    ],
    request_body: {},
    responses: [
      ok: {"ChoregraphiesResponse response", "application/json", Schemas.ChoregraphiesResponse},
      not_found: {"Not found", "application/json", AlfredpiUiWeb.Schemas.NotFound}
    ]
  )

  def play(conn, %{"code" => code}) do
    case ChoregraphyManager.get_choregraphy_by_code(code) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(html: AlfredpiUiWeb.ErrorHTML, json: AlfredpiUiWeb.ErrorJSON)
        |> render(:"404")

      choregraphy ->
        ChoregraphyManager.execute_choregraphy(code)

        render(conn, :play, choregraphy: choregraphy)
    end
  end
end
