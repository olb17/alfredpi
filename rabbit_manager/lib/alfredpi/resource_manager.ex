defmodule Alfredpi.ResourceManager do
  require Logger

  @moduledoc """
    A module to manage resources (mainly sound files) for Alfredpi applications. It caches the resources in a local directory after first download.
  """

  @doc """
    Retrieves a resource by its name from the specified root URL. If the resource is not found locally, it downloads it. 
    
    Returns the local path of the resource.

    ## Examples

    iex> get_resource("https://example.com/resources", "sound.mp3")

    {:ok, "/path/to/local/storage/resources/sound.mp3"}
  """
  @spec get_resource(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def get_resource(root, resource_name) do
    root_hash = :crypto.hash(:sha, root) |> Base.encode16(case: :lower)
    resource_path = Path.join([storage_dir(), root_hash, resource_name])

    if File.exists?(resource_path) do
      {:ok, resource_path}
    else
      download_resource(root, resource_name, resource_path)
    end
  end

  @doc """
    Cleans the resources directory by removing all files and subdirectories.
  """
  @spec clean_resources() :: :ok | {:error, :directory_not_found}
  def clean_resources() do
    storage_dir = storage_dir()

    if File.exists?(storage_dir) do
      File.rm_rf!(storage_dir)
      Logger.info("[Alfredpi.ResourceManager] Cleaned resources directory: #{storage_dir}")
      :ok
    else
      Logger.warning(
        "[Alfredpi.ResourceManager] Resources directory does not exist: #{storage_dir}"
      )

      {:error, :directory_not_found}
    end
  end

  defp download_resource(root, resource_name, resource_path) do
    url = URI.append_path(URI.parse(root), "/" <> resource_name)

    File.mkdir_p!(Path.dirname(resource_path))

    with {:ok, response} <- Req.get(url),
         {:error, 200} <- {:error, response.status},
         :ok <- File.write(resource_path, response.body, [:binary]) do
      Logger.info("[Alfredpi.ResourceManager] Downloaded resource: #{url}")
      {:ok, resource_path}
    else
      {:error, err} ->
        Logger.warning("[Alfredpi.Surprise] Cannot download or store #{url}: #{inspect(err)}")
        {:error, err}
    end
  end

  defp storage_dir() do
    Application.fetch_env!(:rabbit_manager, :dir)
    |> Path.join("resources")
  end
end
