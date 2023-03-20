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

  def handle_info({:number, new_number}, _number) do
    {:noreply, new_number}
  end

  @impl true
  def handle_info(message, number) do
    text = message["message"]["tweet"]["text"]
    time = :os.timestamp() |> elem(0) |> div(1_000) |> to_string()

    msg_id = :crypto.hash(:sha256, text <> time)

    printer_id = :crypto.hash(:sha256, text <> time) |> :binary.last()

    0..2
    |> Enum.each(fn range ->
      printer_id = rem(printer_id + range, number)

      if Process.whereis(:"printer#{printer_id}") != nil,
        do: send(:"printer#{printer_id}", {:msg, {msg_id, message}})
    end)

    send(HashtagPrinter, message)
    {:noreply, number}
  end
end
