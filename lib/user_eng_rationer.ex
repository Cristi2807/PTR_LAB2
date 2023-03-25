defmodule UserEngRationer do
  use GenServer

  def start_link(state) do
    IO.puts("UserEngRationer starting")
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_call({:count, {id, value}}, _, state) do
    case Map.get(state, id) do
      nil ->
        state = Map.put(state, id, value)
        {:reply, value, state}

      avg ->
        new_avg = (avg + value) / 2
        state = Map.put(state, id, new_avg)
        {:reply, new_avg, state}
    end
  end

  def count_avg(id, value) do
    GenServer.call(__MODULE__, {:count, {id, value}})
  end
end
