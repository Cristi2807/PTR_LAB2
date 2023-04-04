defmodule Database do
  use GenServer

  def start_link(arg \\ :ok) do
    IO.puts("DataBase starting")
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    :ets.new(:users, [:ordered_set, :protected, :named_table])
    :ets.new(:tweets, [:ordered_set, :protected, :named_table])
    {:ok, 0}
  end

  def handle_call({:save, map}, _, state_id) do
    :ets.insert(
      :tweets,
      {state_id, map[:redactor], map[:sentiment_score], map[:eng_ratio], map[:user]}
    )

    :ets.insert(
      :users,
      {map[:user], map[:eng_ratio_user]}
    )

    state_id = state_id + 1
    {:reply, :ok, state_id}
  end
end
