defmodule Chess.Repo.Migrations.AddFenAndMovesToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :fen, :string,
        null: false,
        default: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

      add :moves, {:array, :string}, null: false, default: []
    end
  end
end
