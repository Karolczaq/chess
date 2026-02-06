defmodule Chess.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :status, :string
    field :creator_name, :string
    field :white_player_id, :string
    field :black_player_id, :string
    field :fen, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:status, :creator_name, :white_player_id, :black_player_id, :fen])
    |> validate_required([:status, :creator_name, :white_player_id])
  end

  def join_changeset(game, player_id) do
    game
    |> cast(%{black_player_id: player_id, status: "ongoing"}, [:black_player_id, :status])
    |> validate_required([:black_player_id, :status])
  end
end
