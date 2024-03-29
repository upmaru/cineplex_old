defmodule Cineplex.Repo.Migrations.CreateQueueSources do
  use Ecto.Migration

  def change do
    create table(:queue_sources) do
      add :name, :string
      add :endpoint, :string
      add :reel, :string

      add :token, :text

      add :storage, :map

      timestamps()
    end

    create index(:queue_sources, [:endpoint], unique: true)
  end
end
