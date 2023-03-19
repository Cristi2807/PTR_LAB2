defmodule WorkerManager do
  use GenServer

  def start_link([delay, min_workers, max_workers, task_per_worker]) do
    IO.puts("Worker Manager starting")

    {:ok, pid} =
      GenServer.start_link(__MODULE__, {delay, min_workers, max_workers, task_per_worker},
        name: __MODULE__
      )

    Process.send_after(pid, :check, delay)

    {:ok, pid}
  end

  def init({delay, min_workers, max_workers, task_per_worker}) do
    {:ok, {delay, min_workers, max_workers, task_per_worker}}
  end

  defp getData() do
    nr_of_workers = Supervisor.count_children(WorkerPool)[:specs] - 1

    nr_of_tasks =
      WorkerPool
      |> Supervisor.which_children()
      |> Enum.reduce(0, fn {_, pid, _, _}, acc ->
        {_, queue_len} = Process.info(pid, :message_queue_len)
        acc + queue_len
      end)

    {nr_of_tasks / nr_of_workers, nr_of_workers}
  end

  def handle_info(:check, {delay, min_workers, max_workers, task_per_worker}) do
    {avg_tasks, nr_of_workers} = getData()
    send(LoadBalancer, {:number, nr_of_workers})
    IO.puts(avg_tasks)

    cond do
      nr_of_workers > max_workers ->
        Supervisor.terminate_child(WorkerPool, :"printer#{nr_of_workers}")
        Supervisor.delete_child(WorkerPool, :"printer#{nr_of_workers}")

      nr_of_workers < min_workers ->
        Supervisor.start_child(WorkerPool, %{
          id: :"printer#{nr_of_workers + 1}",
          start: {Printer, :start_link, [:"printer#{nr_of_workers + 1}", 5, 50]}
        })

      avg_tasks > task_per_worker && nr_of_workers < max_workers ->
        Supervisor.start_child(WorkerPool, %{
          id: :"printer#{nr_of_workers + 1}",
          start: {Printer, :start_link, [:"printer#{nr_of_workers + 1}", 5, 50]}
        })

      avg_tasks < task_per_worker && nr_of_workers > min_workers ->
        Supervisor.terminate_child(WorkerPool, :"printer#{nr_of_workers}")
        Supervisor.delete_child(WorkerPool, :"printer#{nr_of_workers}")
        IO.puts(":printer#{nr_of_workers} deleted by Worker Manager")

      true ->
        nil
    end

    Process.send_after(self(), :check, delay)
    {:noreply, {delay, min_workers, max_workers, task_per_worker}}
  end
end
