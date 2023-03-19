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

    current =
      :crypto.hash(:sha256, text)
      |> :binary.last()
      |> rem(number)

    id = :"printer#{current + 1}"
    if Process.whereis(id) != nil, do: send(id, message)

    send(HashtagPrinter, message)
    {:noreply, number}
  end
end
