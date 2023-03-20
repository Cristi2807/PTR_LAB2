defmodule Printer do
  use GenServer

  def start_link(id, min_time, max_time) do
    IO.puts("#{id} is starting")
    GenServer.start_link(__MODULE__, {id, min_time, max_time}, name: id)
  end

  @impl true
  def init({id, min_time, max_time}) do
    {:ok, bad_words_json} = File.read("./lib/bad_words.json")
    {:ok, bad_words_dict} = Poison.decode(bad_words_json)

    {:ok, {id, min_time, max_time, bad_words_dict}}
  end

  @impl true
  def handle_info(:crash, {id, min_time, max_time, _bad_words_dict}) do
    IO.puts("#{id} received CRASH msg, GOING OFF")
    exit(:crash)
    {:noreply, {id, min_time, max_time}}
  end

  @impl true
  def handle_info({:msg, {msg_id, json}}, {id, min_time, max_time, bad_words_dict}) do
    lambda = (max_time - min_time) / 2

    (min_time + round(Statistics.Distributions.Poisson.rand(lambda)))
    |> Process.sleep()

    words = String.split(json["message"]["tweet"]["text"], " ", trim: true)

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

    case OutputQueue.check_msg_id(msg_id) do
      :ok ->
        IO.puts("#{id}: #{formattedWords}")
        nil

      :err ->
        IO.puts("\e[31m #{id}: Message ALREADY PRINTED! \e[0m")
        nil
    end

    {:noreply, {id, min_time, max_time, bad_words_dict}}
  end
end
