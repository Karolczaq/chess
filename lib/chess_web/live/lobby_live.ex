defmodule ChessWeb.LobbyLive do
  use ChessWeb, :live_view

  alias Chess.Games

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: Games.subscribe_lobby()

    username = session["username"] || ""

    if connected?(socket) and username != "" do
      Games.list_waiting_games()
      |> Enum.filter(&(&1.creator_name == username))
      |> Enum.each(&Games.subscribe_to_game(&1.id))
    end

    socket =
      socket
      |> assign(:username, username)
      |> stream(:games, Games.list_waiting_games())

    {:ok, socket}
  end

  defp game_row(assigns) do
    ~H"""
    <div id={@dom_id} class="flex items-center justify-between p-4 bg-white border rounded">
      <span class="text-black">{@game.creator_name} is waiting...</span>
      <%= if @game.creator_name == @username do %>
        <button
          phx-click="cancel_game"
          phx-value-id={@game.id}
          class="px-4 py-2 bg-red-600 text-white rounded"
        >
          Cancel
        </button>
      <% else %>
        <button
          phx-click="join_game"
          phx-value-id={@game.id}
          class="px-4 py-2 bg-green-600 text-white rounded"
        >
          Join
        </button>
      <% end %>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flash kind={:error} flash={@flash} />
    <.flash kind={:info} flash={@flash} />
    <div class="max-w-2xl mx-auto">
      <h1 class="text-2xl font-bold mb-6">Chess Lobby</h1>

      <div class="mb-6 flex items-center gap-4">
        <input
          type="text"
          placeholder="Enter your username"
          value={@username}
          phx-blur="set_username"
          phx-keyup="set_username"
          class="px-3 py-2 border rounded text-black"
        />
        <button
          phx-click="create_game"
          disabled={@username == ""}
          class="px-4 py-2 bg-blue-600 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Create Game
        </button>
        <button
          phx-click="finish_all_games"
          class="px-4 py-2 bg-red-600 text-white rounded"
        >
          Finish All Games
        </button>
      </div>

      <div id="games" phx-update="stream" class="space-y-3">
        <.game_row
          :for={{dom_id, game} <- @streams.games}
          game={game}
          dom_id={dom_id}
          username={@username}
        />
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("set_username", %{"value" => username}, socket) do
    Games.list_waiting_games()
    |> Enum.filter(&(&1.creator_name == username))
    |> Enum.each(&Games.subscribe_to_game(&1.id))

    {:noreply, assign(socket, :username, username)}
  end

  @impl true
  def handle_event("create_game", _params, socket) do
    username = socket.assigns.username

    case Games.create_game(%{creator_name: username, status: "waiting", white_player_id: "temp"}) do
      {:ok, game} ->
        Games.subscribe_to_game(game.id)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not create game")}
    end
  end

  @impl true
  def handle_event("join_game", %{"id" => game_id}, socket) do
    username = socket.assigns.username

    if username == "" do
      {:noreply, put_flash(socket, :error, "Please enter a username first")}
    else
      case Games.get_game!(game_id) |> Games.join_game(username) do
        {:ok, _game} ->
          {:noreply, push_navigate(socket, to: "/games/#{game_id}")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not join game")}
      end
    end
  end

  @impl true
  def handle_event("cancel_game", %{"id" => game_id}, socket) do
    game = Games.get_game!(game_id)
    Games.delete_game(game)
    {:noreply, stream_delete(socket, :games, game)}
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

  @impl true
  def handle_info({:game_joined, game_id, _game}, socket) do
    {:noreply, push_navigate(socket, to: "/games/#{game_id}")}
  end

  @impl true
  def handle_info({:game_joined, game}, socket) do
    {:noreply, stream_delete(socket, :games, game)}
  end

  @impl true
  def handle_info({:game_cancelled, game}, socket) do
    Phoenix.PubSub.unsubscribe(Chess.PubSub, "game:#{game.id}")
    {:noreply, stream_delete(socket, :games, game)}
  end
end
