defmodule LoadBalancer do
  use GenServer

  def start_link(number) do
    IO.puts("LoadBalancer is starting")
    GenServer.start_link(__MODULE__, number, name: __MODULE__)
  end

  @impl true
  def init(number) do
    {:ok, {0, number}}
  end

  @impl true
  def handle_info(message, {current, number}) do
    id = :"printer#{current + 1}"
    if Process.whereis(id) != nil, do: send(id, message)

    send(HashtagPrinter, message)
    {:noreply, {rem(current + 1, number), number}}
  end
end
