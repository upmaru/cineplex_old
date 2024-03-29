defmodule Cineplex.Reels.UpmaruStudio.Encode do
  alias Cineplex.Queue
  alias Queue.Job
  alias Cineplex.Reels.UpmaruStudio.Encode

  alias Cineplex.Worker.Event

  alias Encode.{
    Setup,
    CheckExisting,
    Download,
    Transcode,
    Store,
    Clean
  }

  @spec perform(Job.Entry.t()) :: {:ok, :encoded} | {:error, any()}
  def perform(%Job.Entry{job: job, preset: preset} = job_entry) do
    with {:ok, authorization, url, path} <- setup(job, preset),
         {:ok, :not_encoded} <- check_existing(authorization, job, preset),
         {:ok, downloaded} <- download(job_entry, url, path),
         {:ok, transcoded} <- transcode(job, preset, downloaded),
         {:ok, :stored} <- store(authorization, job, preset, transcoded),
         {:ok, :cleaned} <- clean(job, preset, path) do
      {:ok, :encoded}
    else
      {:error, reason} ->
        Event.track(job, Atom.to_string(reason), %{preset_name: preset.name})
        {:error, reason}
    end
  end

  defp setup(job, preset) do
    Event.track(job, "setup", %{preset_name: preset.name})
    Setup.perform(job)
  end

  defp check_existing(authorization, job, preset) do
    Event.track(job, "check_existing", %{preset_name: preset.name})
    CheckExisting.perform(authorization, job, preset)
  end

  defp download(%Job.Entry{job: job, preset: preset} = job_entry, url, path) do
    Event.track(job, "download", %{preset_name: preset.name})

    Download.perform(url, path,
      on_fail: fn ->
        Event.track(job, "retry", %{preset_name: preset.name})
        Queue.retry_job_entry(job_entry)
      end
    )
  end

  defp transcode(job, preset, downloaded) do
    Event.track(job, "transcode", %{preset_name: preset.name})
    Transcode.perform(preset, downloaded)
  end

  defp store(authorization, job, preset, transcoded) do
    Event.track(job, "store", %{preset_name: preset.name})

    Store.perform(authorization, preset, transcoded,
      on_done: fn ->
        Event.track(job, "uploaded", %{preset_name: preset.name})
      end
    )
  end

  defp clean(job, preset, path) do
    Event.track(job, "clean", %{preset_name: preset.name})
    Clean.perform(path)
  end
end
