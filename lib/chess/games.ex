defmodule Chess.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false
  alias Chess.Repo

  alias Chess.Games.Game

  @topic "lobby"

  def subscribe do
    Phoenix.PubSub.subscribe(Chess.PubSub, @topic)
  end

  defp broadcast({:ok, game}, event) do
    Phoenix.PubSub.broadcast(Chess.PubSub, @topic, {event, game})
    {:ok, game}
  end

  def list_waiting_games do
    Game
    |> where(status: "waiting")
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def join_game(%Game{} = game, player_id) do
    game
    |> Game.join_changeset(%{black_player_id: player_id, status: "ongoing"})
    |> Repo.update()
    |> broadcast(:game_joined)
  end

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  def list_games do
    Repo.all(Game)
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game(attrs) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:game_created)
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  def finish_all_games do
    from(g in Game)
    |> Repo.update_all(set: [status: "finished"])
  end
end
