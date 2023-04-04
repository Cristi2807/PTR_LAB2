defmodule MainSupervisor do
  use Supervisor

  def start_link(init_arg \\ :ok) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Batcher, [[], 100]},
      {Database, []},
      {Aggregator, []},
      %{
        id: :redactorPool,
        start: {WorkerPool, :start_link, [Redactor, :redactor, 3, []]}
      },
      %{
        id: :sentiment_scorerPool,
        start: {WorkerPool, :start_link, [SentimentScorer, :sentiment_scorer, 3, []]}
      },
      %{
        id: :engagement_rationerPool,
        start: {WorkerPool, :start_link, [EngagementRationer, :engagement_rationer, 3, []]}
      },
      {UserEngRationer, %{}},
      {HashtagPrinter, []},
      {LoadBalancer, 3},
      {RetweetChecker, []},
      %{
        id: :reader1,
        start: {Reader, :start_link, [:reader1, "localhost:4000/tweets/1"]}
      },
      %{
        id: :reader2,
        start: {Reader, :start_link, [:reader2, "localhost:4000/tweets/2"]}
      }
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
