defmodule Cineplex.Worker.Finish do
  alias Cineplex.{
    Distribution,
    Queue,
    Repo,
    Worker
  }

  alias Queue.Job
  alias Worker.Event

  alias Ecto.Multi

  @spec perform(
          {map(), map()}
          | %{:__struct__ => atom() | %{__changeset__: map()}, optional(atom()) => any()}
        ) :: any()
  def perform(%Job.Entry{job: job, preset: preset} = job_entry) do
    myself = Distribution.get_worker(name: Atom.to_string(node()))

    Multi.new()
    |> Multi.update(:job_entry, finish_changeset(job_entry))
    |> Multi.update(:worker, ready_changeset(myself))
    |> Repo.transaction()

    Event.track(job, "finish", %{preset_name: preset.name})
  end

  defp finish_changeset(job_entry) do
    Job.Entry.changeset(job_entry, %{finished_at: DateTime.utc_now()})
  end

  defp ready_changeset(worker) do
    Distribution.Node.changeset(worker, %{current_state: "ready"})
  end
end
