defmodule ChessWeb.LobbyLive do
  use ChessWeb, :live_view

  alias Chess.Games

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Chess.Games.subscribe()
    {:ok, stream(socket, :games, Chess.Games.list_waiting_games())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-2xl font-bold mb-6">Chess Lobby</h1>

      <button phx-click="create_game" class="mb-6 px-4 py-2 bg-blue-600 text-white rounded">
        Create Game
      </button>

      <button
        phx-click="finish_all_games"
        class="mb-6 px-4 py-2 bg-red-600 text-white rounded"
      >
        Finish All Games
      </button>

      <div id="games" phx-update="stream" class="space-y-3">
        <div
          :for={{dom_id, game} <- @streams.games}
          id={dom_id}
          class="flex items-center justify-between p-4 bg-white border rounded"
        >
          <span class="text-black">{game.creator_name} is waiting...</span>
          <button
            phx-click="join_game"
            phx-value-id={game.id}
            class="px-4 py-2 bg-green-600 text-white rounded"
          >
            Join
          </button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("create_game", _params, socket) do
    case Games.create_game(%{creator_name: "Player", status: "waiting", white_player_id: "temp"}) do
      {:ok, _game} -> {:noreply, socket}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not create game")}
    end
  end

  @impl true
  def handle_event("finish_all_games", _params, socket) do
    Games.finish_all_games()
    {:noreply, socket}
  end

  @impl true
  def handle_info({:game_created, game}, socket) do
    {:noreply, stream_insert(socket, :games, game)}
  end
end
