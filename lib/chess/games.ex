defmodule Chess.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false
  alias Chess.Repo

  alias Chess.Games.Game

  def subscribe_lobby do
    Phoenix.PubSub.subscribe(Chess.PubSub, "lobby")
  end

  defp broadcast_lobby({:ok, game}, event) do
    Phoenix.PubSub.broadcast(Chess.PubSub, "lobby", {event, game})
    {:ok, game}
  end

  defp broadcast_lobby({:error, _} = error, _event), do: error

  def list_waiting_games do
    Game
    |> where(status: "waiting")
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def subscribe_to_game(game_id) do
    Phoenix.PubSub.subscribe(Chess.PubSub, "game:#{game_id}")
  end

  def broadcast_to_game({:ok, %Game{} = game}, event) do
    Phoenix.PubSub.broadcast(Chess.PubSub, "game:#{game.id}", {event, game.id, game})
    {:ok, game}
  end

  def join_game(%Game{status: "waiting"} = game, player_id) do
    with {:ok, game} <- game |> Game.join_changeset(player_id) |> Repo.update(),
         {:ok, _pid} <- Chess.GameServer.start_game(game.id) do
      broadcast_lobby({:ok, game}, :game_joined)
      broadcast_to_game({:ok, game}, :game_joined)
    end
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
    |> Game.create_changeset(attrs)
    |> Repo.insert()
    |> broadcast_lobby(:game_created)
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
    |> Game.create_changeset(attrs)
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
    |> broadcast_lobby(:game_cancelled)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.create_changeset(game, attrs)
  end

  def finish_all_games do
    from(g in Game)
    |> Repo.update_all(set: [status: "finished"])
  end
end
