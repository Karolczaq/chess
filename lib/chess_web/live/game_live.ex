defmodule ChessWeb.GameLive do
  use ChessWeb, :live_view

  alias Chess.GameServer

  @default_fen "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

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

    socket =
      socket
      |> assign(:count, count)
      |> assign(:game_id, game_id)
      |> assign(:fen, @default_fen)
      |> assign(:board, parse_fen(@default_fen))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-2xl font-bold mb-6">Game {@game_id}</h1>

      <div class="grid grid-cols-8 w-96 h-96 border-2 border-gray-800 mx-auto">
        <%= for {piece, index} <- Enum.with_index(@board) do %>
          <div class={[
            "w-12 h-12 flex items-center justify-center",
            square_color(index)
          ]}>
            <%= if piece do %>
              <img src={piece_image(piece)} class="w-10 h-10" />
            <% end %>
          </div>
        <% end %>
      </div>

      <p class="mt-4 text-sm text-gray-600 font-mono">{@fen}</p>
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

  @impl true
  def handle_info({:fen_updated, fen}, socket) do
    {:noreply, socket |> assign(:fen, fen) |> assign(:board, parse_fen(fen))}
  end

  # --- Board helpers ---

  defp parse_fen(fen) do
    fen
    |> String.split(" ")
    |> hd()
    |> String.split("/")
    |> Enum.flat_map(&expand_row/1)
  end

  defp expand_row(row) do
    row
    |> String.graphemes()
    |> Enum.flat_map(fn char ->
      case Integer.parse(char) do
        {n, _} -> List.duplicate(nil, n)
        :error -> [char]
      end
    end)
  end

  defp square_color(index) do
    row = div(index, 8)
    col = rem(index, 8)

    if rem(row + col, 2) == 0 do
      "bg-amber-200"
    else
      "bg-amber-700"
    end
  end

  defp piece_image("K"), do: "/images/pieces/wK.svg"
  defp piece_image("Q"), do: "/images/pieces/wQ.svg"
  defp piece_image("R"), do: "/images/pieces/wR.svg"
  defp piece_image("B"), do: "/images/pieces/wB.svg"
  defp piece_image("N"), do: "/images/pieces/wN.svg"
  defp piece_image("P"), do: "/images/pieces/wP.svg"
  defp piece_image("k"), do: "/images/pieces/bK.svg"
  defp piece_image("q"), do: "/images/pieces/bQ.svg"
  defp piece_image("r"), do: "/images/pieces/bR.svg"
  defp piece_image("b"), do: "/images/pieces/bB.svg"
  defp piece_image("n"), do: "/images/pieces/bN.svg"
  defp piece_image("p"), do: "/images/pieces/bP.svg"
end
