defmodule AlfredpiUiWeb.Schemas do
  alias OpenApiSpex.Schema

  defmodule Choregraphy do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Choregraphy",
      description: "A choregraphy which can be played by Alfred",
      type: :object,
      properties: %{
        code: %Schema{type: :string, description: "Choregraphy code"},
        name: %Schema{type: :string, description: "Choregraphy name"}
      },
      required: [:code, :name],
      example: %{
        "code" => "CODE_1",
        "name" => "Nom de la choregrpahy"
      }
    })
  end

  defmodule ChoregraphiesResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "ChoregraphiesResponse",
      description: "Response schema for multiple choregraphies",
      type: :object,
      properties: %{
        data: %Schema{description: "The choregraphy details", type: :array, items: Choregraphy}
      },
      example: %{
        "data" => [
          %{
            "code" => "CODE_1",
            "name" => "choregraphy 1 name"
          },
          %{
            "code" => "CODE_2",
            "name" => "choregraphy name 2"
          }
        ]
      }
    })
  end

  defmodule NotFound do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "NotFound",
      description: "Object Not Found",
      type: :object,
      properties: %{
        errors: %Schema{
          description: "The errors details",
          type: :array,
          items: %Schema{description: "The error detail", type: :string}
        }
      },
      example: %{
        "errors" => [
          %{
            "detail" => "error 1"
          },
          %{
            "detail" => "error 2"
          }
        ]
      }
    })
  end
end
