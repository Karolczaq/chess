defmodule Chess.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chess.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(attrs \\ %{}) do
    {:ok, game} =
      attrs
      |> Enum.into(%{
        black_player_id: "some black_player_id",
        creator_name: "some creator_name",
        fen: "some fen",
        status: "some status",
        white_player_id: "some white_player_id"
      })
      |> Chess.Games.create_game()

    game
  end
end
