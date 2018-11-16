defmodule Compressor.Queue do
  alias Compressor.Queue.{
    Job,
    Source
  }

  alias Compressor.Repo

  @spec create_source(binary(), binary(), binary()) ::
          {:error, Ecto.Changeset.t()} | {:ok, Source.t()}
  def create_source(endpoint, token, adapter) do
    %Source{}
    |> Source.changeset(%{endpoint: endpoint, token: token, adapter: adapter})
    |> Repo.insert()
  end

  @spec update_source(Source.t(), map()) :: {:error, Ecto.Changeset.t()} | {:ok, Source.t()}
  def update_source(source, parameters) do
    source
    |> Source.changeset(parameters)
    |> Repo.update()
  end

  @spec create_job(Source.t(), map()) :: {:error, Ecto.Changeset.t()} | {:ok, Job.t()}
  def create_job(source, params) do
    %Job{source: source}
    |> Job.changeset(params)
    |> Repo.insert()
  end

  @spec update_job(Job.t(), map()) :: {:error, Ecto.Changeset.t()} | {:ok, Job.t()}
  def update_job(job, parameters) do
    job
    |> Job.changeset(parameters)
    |> Repo.update()
  end

  @spec get_job_entries(any()) :: [Job.Entry.t()] | []
  def get_job_entries(state) do
    Job.Entry
    |> Job.Entry.Scope.by(state)
    |> Repo.all()
  end
end
