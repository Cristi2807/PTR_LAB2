defmodule SentimentScorer do
  use GenServer

  def start_link(id) do
    IO.puts("#{id} is starting")
    GenServer.start_link(__MODULE__, {id}, name: id)
  end

  @impl true
  def init({id}) do
    score_map =
      HTTPoison.get!("localhost:4000/emotion_values").body
      |> String.split("\r\n", trim: true)
      |> Enum.reduce([], fn pair, acc ->
        map_values =
          pair
          |> String.split("\t", trim: true)

        acc ++ [%{word: Enum.at(map_values, 0), score: Enum.at(map_values, 1)}]
      end)

    {:ok, {id, score_map}}
  end

  @impl true
  def handle_info({:msg, {msg_id, json}}, {id, score_map}) do
    words = String.split(json["text"], " ", trim: true)

    sum =
      words
      |> Enum.reduce(0, fn word, acc ->
        case Enum.find(score_map, fn %{:word => value} ->
               value == word |> String.downcase()
             end) do
          nil ->
            acc

          word_found ->
            acc + String.to_integer(word_found[:score])
        end
      end)

    score = sum / length(words)

    send(Aggregator, {:set, {msg_id, :sentiment_score, score}})

    {:noreply, {id, score_map}}
  end
end
