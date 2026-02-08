defmodule ChessWeb.GameLive do
  use ChessWeb, :live_view

  alias Chess.GameServer

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    game_id = String.to_integer(game_id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Chess.PubSub, "game:#{game_id}")
    end

    count =
      case GameServer.get_count(game_id) do
        {:error, :not_found} -> nil
        count -> count
      end

    {:ok, assign(socket, count: count, game_id: game_id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-2xl font-bold mb-6">Game Live View</h1>
      <p>Current count: {@count}</p>
      <button
        phx-click="increment"
        class="px-4 py-2 bg-blue-600 text-white rounded"
      >
        Increment
      </button>
    </div>
    """
  end

  @impl true
  def handle_event("increment", _params, socket) do
    GameServer.increment(socket.assigns.game_id)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:count_updated, count}, socket) do
    {:noreply, assign(socket, count: count)}
  end
end
