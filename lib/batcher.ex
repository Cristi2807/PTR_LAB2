defmodule Batcher do
  use GenServer

  def start_link([state, buffer_size, max_time]) do
    IO.puts("Batcher starting")
    GenServer.start_link(__MODULE__, {state, buffer_size, max_time}, name: __MODULE__)
  end

  @impl true
  def init({state, buffer_size, max_time}) do
    pid = spawn_link(fn -> loopBufferTimeout(max_time) end)
    Process.register(pid, :batcher_checker)
    {:ok, {state, buffer_size}}
  end

  def loopBufferTimeout(max_time) do
    receive do
      {:bufferfull, state} ->
        print_state(state)
        loopBufferTimeout(max_time)
    after
      max_time ->
        state = GenServer.call(Batcher, :get_state)
        send(Batcher, :set_state)
        print_state(state)
        loopBufferTimeout(max_time)
    end
  end

  def print_state(state) do
    state
    |> Enum.each(fn merged_map ->
      IO.puts(
        "\e[38;5;196m Redactor: \e[0m #{merged_map[:redactor]} \e[38;5;46m Emotional Score: \e[0m #{merged_map[:sentiment_score]}
         \e[38;5;21m Eng Ratio: \e[0m #{merged_map[:eng_ratio]} \e[38;5;100m Eng Ratio User: \e[0m #{merged_map[:eng_ratio_user]}\n"
      )
    end)
  end

  @impl true
  def handle_call(:get_state, _, {state, buffer_size}) do
    {:reply, state, {state, buffer_size}}
  end

  @impl true
  def handle_info(:set_state, {_state, buffer_size}) do
    {:noreply, {[], buffer_size}}
  end

  @impl true
  def handle_info({:send, map}, {state, buffer_size}) do
    state = state ++ [map]

    state =
      case length(state) == buffer_size do
        true ->
          send(:batcher_checker, {:bufferfull, state})
          []

        false ->
          state
      end

    {:noreply, {state, buffer_size}}
  end
end
