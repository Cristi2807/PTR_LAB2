defmodule EngagementRationer do
  use GenServer

  def start_link(id) do
    IO.puts("#{id} is starting")
    GenServer.start_link(__MODULE__, {id}, name: id)
  end

  @impl true
  def init({id}) do
    {:ok, {id}}
  end

  @impl true
  def handle_info({:msg, {msg_id, json}}, {id}) do
    favourites = json["favorite_count"]
    retweets = json["retweet_count"]
    followers = json["user"]["followers_count"]

    eng_ratio =
      if followers == 0,
        do: 0,
        else: (favourites + retweets) / followers

    send(Aggregator, {:set, {msg_id, :eng_ratio, eng_ratio}})

    send(
      Aggregator,
      {:set, {msg_id, :eng_ratio_user, UserEngRationer.count_avg(json["user"]["id"], eng_ratio)}}
    )

    {:noreply, {id}}
  end
end
