defmodule WorkerPool do
  use Supervisor

  def start_link(module, id, nr_of_workers, worker_args) do
    Supervisor.start_link(__MODULE__, {module, id, nr_of_workers, worker_args}, name: :"#{id}Pool")
  end

  @impl true
  def init({module, id, nr_of_workers, worker_args}) do
    children =
      1..nr_of_workers
      |> Enum.reduce([], fn number, acc ->
        acc ++
          [
            %{
              id: :"#{id}#{number}",
              start: {module, :start_link, [:"#{id}#{number}"] ++ worker_args}
            }
          ]
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
