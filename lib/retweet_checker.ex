defmodule RetweetChecker do
  use GenServer

  def start_link(init_arg \\ :ok) do
    IO.puts("Retweet Checker starting")
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_info(json, state) do
    send(LoadBalancer, json)

    case Map.has_key?(json, "retweeted_status") do
      false ->
        nil

      true ->
        send(self(), json["retweeted_status"])
    end

    {:noreply, state}
  end
end
