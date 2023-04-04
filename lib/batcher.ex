defmodule Batcher do
  use GenServer

  def start_link([state, buffer_size]) do
    IO.puts("Batcher starting")
    {:ok, pid} = GenServer.start_link(__MODULE__, {state, buffer_size}, name: __MODULE__)
    send(pid, :print)
    {:ok, pid}
  end

  @impl true
  def init({state, buffer_size}) do
    {:ok, {state, buffer_size, false}}
  end

  def print_state(merged_map) do
    IO.puts(
      "\e[38;5;196m Redactor: \e[0m #{merged_map[:redactor]} \e[38;5;46m Emotional Score: \e[0m #{merged_map[:sentiment_score]}
         \e[38;5;21m Eng Ratio: \e[0m #{merged_map[:eng_ratio]} \e[38;5;100m Eng Ratio User: \e[0m #{merged_map[:eng_ratio_user]}\n"
    )
  end

  @impl true
  def handle_info(:database_active, {state, buffer_size, _conn}) do
    {:noreply, {state, buffer_size, true}}
  end

  @impl true
  def handle_info(:print, {state, buffer_size, db_conn}) do
    # IO.puts(length(state))

    state =
      case length(state) > 0 && db_conn == true do
        true ->
          try do
            GenServer.call(Database, {:save, Enum.at(state, 0)})
          catch
            :timeout ->
              IO.puts("Request timed out!")
          end

          Enum.drop(state, 1)

        false ->
          state
      end

    send(self(), :print)

    {:noreply, {state, buffer_size, db_conn}}
  end

  @impl true
  def handle_info(:stop, {state, buffer_size, db_conn}) do
    case length(state) > buffer_size / 2 do
      true ->
        send(self(), :stop)

      false ->
        send(Aggregator, :start)
        # IO.puts("\e[38;5;46m Buffer size less than half Buffer_size. READY TO RECEIVE \e[0m")
    end

    {:noreply, {state, buffer_size, db_conn}}
  end

  @impl true
  def handle_info({:send, map}, {state, buffer_size, db_conn}) do
    state = state ++ [map]

    case length(state) == buffer_size do
      true ->
        send(Aggregator, :stop)
        send(self(), :stop)

      # IO.puts("\e[38;5;196m Batcher Buffer FULL! STOP sent to Aggregator! \e[0m")

      false ->
        nil
    end

    {:noreply, {state, buffer_size, db_conn}}
  end
end
