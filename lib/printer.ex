defmodule Printer do
  use GenServer

  def start_link({min_time, max_time}) do
    GenServer.start_link(__MODULE__, {min_time, max_time}, name: __MODULE__)
  end

  @impl true
  def init({min_time, max_time}) do
    {:ok, {min_time, max_time}}
  end

  @impl true
  def handle_info(json, {min_time, max_time}) do
    lambda = (max_time - min_time) / 2

    (min_time + round(Statistics.Distributions.Poisson.rand(lambda)))
    |> Process.sleep()

    IO.puts(json["message"]["tweet"]["text"])
    {:noreply, {min_time, max_time}}
  end
end
