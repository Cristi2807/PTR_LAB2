defmodule Redactor do
  use GenServer

  def start_link(id) do
    IO.puts("#{id} is starting")
    GenServer.start_link(__MODULE__, {id}, name: id)
  end

  @impl true
  def init({id}) do
    {:ok, bad_words_json} = File.read("./lib/bad_words.json")
    {:ok, bad_words_dict} = Poison.decode(bad_words_json)

    {:ok, {id, bad_words_dict}}
  end

  @impl true
  def handle_info({:msg, {msg_id, json}}, {id, bad_words_dict}) do
    words = String.split(json["text"], " ", trim: true)

    formattedWords =
      Enum.map(words, fn word ->
        case Enum.find(bad_words_dict["RECORDS"], fn %{"word" => value} ->
               value == word |> String.downcase()
             end) do
          nil ->
            word

          badWord ->
            badWord["word"]
            |> String.split("", trim: true)
            |> Enum.map(fn _ -> "*" end)
            |> Enum.join()
        end
      end)
      |> Enum.join(" ")

    send(Aggregator, {:set, {msg_id, :redactor, formattedWords}})

    {:noreply, {id, bad_words_dict}}
  end
end
