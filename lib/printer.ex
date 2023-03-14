defmodule Printer do
  use GenServer

  def start_link(id, min_time, max_time) do
    IO.puts("#{id} is starting")
    GenServer.start_link(__MODULE__, {id, min_time, max_time}, name: id)
  end

  @impl true
  def init({id, min_time, max_time}) do
    {:ok, {id, min_time, max_time}}
  end

  @impl true
  def handle_info(json, {id, min_time, max_time}) do
    lambda = (max_time - min_time) / 2

    (min_time + round(Statistics.Distributions.Poisson.rand(lambda)))
    |> Process.sleep()

    IO.puts("#{id}: #{json["message"]["tweet"]["text"]}")
    {:noreply, {id, min_time, max_time}}
  end
end
