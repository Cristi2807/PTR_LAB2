defmodule Aggregator do
  use GenServer

  def start_link(state) do
    IO.puts("Aggregator starting")
    {:ok, pid} = GenServer.start_link(__MODULE__, state, name: __MODULE__)
    send(pid, :send)
    {:ok, pid}
  end

  @impl true
  def init(_state) do
    {:ok, {%{}, [], true}}
  end

  @impl true
  def handle_info(:start, {state, list, _cons_req}) do
    {:noreply, {state, list, true}}
  end

  @impl true
  def handle_info(:stop, {state, list, _cons_req}) do
    {:noreply, {state, list, false}}
  end

  @impl true
  def handle_info(:send, {state, list, cons_req}) do
    list =
      case cons_req == true && length(list) > 0 do
        true ->
          send(Batcher, {:send, Enum.at(list, 0)})
          Enum.drop(list, 1)

        false ->
          list
      end

    send(self(), :send)
    {:noreply, {state, list, cons_req}}
  end

  @impl true
  def handle_info({:set, {id, key, value}}, {state, list, cons_req}) do
    current_map =
      case Map.get(state, id) do
        nil ->
          %{}

        map ->
          map
      end

    merged_map =
      current_map
      |> Map.merge(%{key => value})

    state =
      case map_size(merged_map) == 4 do
        true ->
          Map.delete(state, id)

        false ->
          Map.put(state, id, merged_map)
      end

    list =
      case map_size(merged_map) == 4 do
        true ->
          list ++ [merged_map]

        false ->
          list
      end

    {:noreply, {state, list, cons_req}}
  end
end
