defmodule ChessWeb.GameLive do
  use ChessWeb, :live_view

  alias Chess.Games

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-2xl font-bold mb-6">Game Live View</h1>
      <p>This is where the game will be displayed.</p>
    </div>
    """
  end
end
