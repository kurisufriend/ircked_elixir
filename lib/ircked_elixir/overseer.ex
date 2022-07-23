defmodule IrckedElixir.Overseer do
  use Supervisor

  @server_address "localhost"
  @server_port 6667
  @base_nick "functism"
  @chatters 20

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = 1..@chatters |> Enum.to_list |> Enum.map(fn n -> %{id: "chatter"<>to_string(n), start: {Task, :start_link, [fn -> IrckedElixir.Chatter.start(@server_address, @server_port, @base_nick <> to_string(n)) end]}} end)
    Supervisor.init(children, strategy: :one_for_one)
  end
end
