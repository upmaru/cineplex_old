defmodule Compressor.Encoder do
  @moduledoc """
  Handles the encoding
  """
  alias Compressor.{
    Presets, TaskSupervisor, Current, Uploader, Events
  }

  alias HTTPoison.Error

  @behaviour Honeydew.Worker

  require Logger

  def perform(name, callback, token) do
    with {:ok, _pid} <- prepare(callback, token),
         {:ok, url, path} <- setup_download(name),
         {:ok, file_path} <- download_source(url, path) do

      file_path
      |> create_variations
      |> Task.yield_many(:infinity)
    end
  end

  def encode_and_upload(options, file_path) do
    name = Map.get(options, "name")
    output_name = generate_output_name(name, file_path)

    Presets.streamable(file_path, output_name, options)
    Task.async(Uploader, :upload, output_name)
  end

  def prepare(callback, token) do
    headers = ["Authorization": "Bearer #{token}"]

    with {:ok, response} <- HTTPoison.get(callback.setting, headers),
         {:ok, settings} <- Poison.decode(response.body),
         {:ok, _pid} <- Current.start_link(settings["data"], callback.resource, headers) do
      Upstream.set_config(Current.storage)
      Events.start_link
    else
      {:error, %Error{reason: reason}} -> {:error, reason}
    end
  end

  defp setup_download(name) do
    {:ok, auth} =
      name
      |> String.split("/")
      |> List.first
      |> Upstream.B2.Download.authorize(3600)

    path = "tmp/" <> name

    with :ok <- path |> Path.dirname |> File.mkdir_p,
         url <- Upstream.B2.Download.url(name, auth.authorization_token) do
      {:ok, url, path}
    end
  end

  defp download_source(url, path) do
    Logger.info "[Compressor] downloading #{path}"
    Download.from(url, [path: path])
  end

  defp create_variations(file_path) do
    Logger.info "[Compressor] encoding #{file_path}"

    Enum.to_list(
      Task.Supervisor.async_stream(
        TaskSupervisor,
        Current.presets,
        __MODULE__,
        :encode_and_upload,
        [file_path],
        max_concurrency: 1,
        timeout: :infinity
      )
    )
  end

  defp generate_output_name(name, file_path) do
    [file_name, extension] =
      file_path
      |> Path.expand
      |> Path.basename
      |> String.split(".")

    Enum.join(
      [
        Path.dirname(file_path), "/",
        file_name, "_", name, ".", extension
      ]
    )
  end
end
