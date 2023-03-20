defmodule OutputQueue do
  use GenServer

  def start_link(state \\ %{}) do
    IO.puts("OutputQueue is starting")
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:msg_id, id}, _, state_map) do
    case Map.get(state_map, id) do
      nil ->
        state_map = Map.put(state_map, id, true)
        {:reply, :ok, state_map}

      _ ->
        {:reply, :err, state_map}
    end
  end

  @spec check_msg_id(any) :: :ok | :err
  def check_msg_id(id) do
    GenServer.call(__MODULE__, {:msg_id, id})
  end
end
