defmodule Chess.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :status, :string
      add :creator_name, :string
      add :white_player_id, :string
      add :black_player_id, :string
      add :fen, :string

      timestamps(type: :utc_datetime)
    end
  end
end
