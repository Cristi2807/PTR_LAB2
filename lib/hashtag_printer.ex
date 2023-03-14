defmodule HashtagPrinter do
  use GenServer

  def start_link(state) do
    IO.puts("Hashtag printer starting")
    {:ok, pid} = GenServer.start_link(__MODULE__, state, name: __MODULE__)
    Process.send_after(pid, :show, 5000)

    {:ok, pid}
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_info(:show, state) do
    {most_popular_hashtag, occurences} =
      state
      |> Enum.reduce(%{}, fn x, acc -> Map.update(acc, x, 1, &(&1 + 1)) end)
      |> Enum.max_by(fn {_k, v} -> v end)

    IO.puts(
      "In the last 5 seconds, the most popular hashtag was #{most_popular_hashtag} with #{occurences} occurences"
    )

    Process.send_after(self(), :show, 5000)
    {:noreply, []}
  end

  def handle_info(json, state) do
    state =
      state ++
        (json["message"]["tweet"]["entities"]["hashtags"]
         |> Enum.map(fn %{"text" => text} -> text end))

    {:noreply, state}
  end
end
