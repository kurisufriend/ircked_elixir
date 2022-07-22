defmodule IrckedElixir do
  use Application

  @impl true
  def start(_type, _args) do
    IO.puts("starting~")
    IrckedElixir.Overseer.start_link(name: IrckedElixir.Overseer)
  end
end
