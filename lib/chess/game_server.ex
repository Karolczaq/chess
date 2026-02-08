defmodule Chess.GameServer do
  use GenServer

  def start_game(game_id) do
    DynamicSupervisor.start_child(Chess.GameSupervisor, {__MODULE__, game_id})
  end

  def increment(game_id) do
    GenServer.call(via(game_id), :increment)
  end

  def get_count(game_id) do
    GenServer.call(via(game_id), :get_count)
  end

  # callbacks

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via(game_id))
  end

  @impl true
  def init(game_id) do
    {:ok, %{game_id: game_id, count: 0}}
  end

  @impl true
  def handle_call(:increment, _from, state) do
    new_state = %{state | count: state.count + 1}

    Phoenix.PubSub.broadcast(
      Chess.PubSub,
      "game:#{state.game_id}",
      {:count_updated, new_state.count}
    )

    {:reply, :ok, new_state}
  end

  def handle_call(:get_count, _from, state) do
    {:reply, state.count, state}
  end

  defp via(game_id) do
    {:via, Registry, {Chess.GameRegistry, game_id}}
  end
end
