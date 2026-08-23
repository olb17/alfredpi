defmodule AlfredpiUiWeb.DownloadSoundFileController do
  use AlfredpiUiWeb, :controller
  require Logger

  def download(conn, %{"file" => file}) do
    Logger.info("Download Sound File")

    filename = Path.basename(file) |> dbg

    conn
    |> put_resp_header("content-disposition", "attachment; filename='#{filename}'")
    |> send_file(200, file)
  end
end
