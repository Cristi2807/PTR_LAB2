defmodule WorkerPool do
  use Supervisor

  def start_link(init_arg \\ :ok) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      %{
        id: :printer1,
        start: {Printer, :start_link, [:printer1, 5, 50]}
      },
      {WorkerManager, [500, 1, 20, 50]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
