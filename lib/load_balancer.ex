defmodule LoadBalancer do
  use GenServer

  def start_link(number) do
    IO.puts("LoadBalancer is starting")
    GenServer.start_link(__MODULE__, number, name: __MODULE__)
  end

  @impl true
  def init(number) do
    {:ok, number}
  end

  @impl true
  def handle_info(message, number) do
    text = message["text"]
    time = :os.timestamp() |> elem(0) |> div(1_000) |> to_string()

    msg_id = :crypto.hash(:sha256, text <> time)

    worker_id = :crypto.hash(:sha256, text <> time) |> :binary.last() |> rem(number)
    worker_id = worker_id + 1

    [
      "redactor",
      "sentiment_scorer",
      "engagement_rationer"
    ]
    |> Enum.each(fn id ->
      if Process.whereis(:"#{id}#{worker_id}") != nil,
        do: send(:"#{id}#{worker_id}", {:msg, {msg_id, message}})
    end)

    send(HashtagPrinter, message)
    {:noreply, number}
  end
end
