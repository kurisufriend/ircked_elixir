defmodule IrckedElixir.ChatGroup do
  use GenServer

  alias IrckedElixir.Chatter.Message, as: Message
  alias IrckedElixir.Chatter.Privmsg, as: Privmsg

  @server_address "localhost"
  @server_port 6667
  @base_nick "functism"
  @chatters 3

  @impl true
  def init(chatters) do
    1..@chatters
    |> Enum.to_list
    |> Enum.map(
      fn n ->
        %{
          id: "chatter"<>to_string(n),
          start: {IrckedElixir.Chatter, :start_link, [%IrckedElixir.Chatter.State{ip: @server_address, port: @server_port, nick: @base_nick <> to_string(n), reporter: n == 1}]}
        }
      end
    )
    |> Enum.each(
      fn child ->
        DynamicSupervisor.start_child(IrckedElixir.DynamicSupervisor, child)
      end
    )
    {:ok, chatters}
  end

  @impl true
  def handle_info({:checkin, nick, chatter}, chatters) do
    chatters = Map.put(chatters, nick, chatter)
    {:noreply, chatters}
  end

  def handle_info({:report, msg}, chatters) do
    case msg.command do
      "PRIVMSG" ->
        pm = Privmsg.parse(msg)
        IO.puts(inspect pm)
        case pm.body do
          ".cunny" -> send_all(chatters, pm.to, "cunny!")
          _ -> ""
        end

      "" -> ""
      _ -> IO.puts(inspect msg)
    end
    {:noreply, chatters}
  end

  def start_link(chatters) do
    GenServer.start_link(__MODULE__, chatters, name: :chatgroup)
  end

  def send_all(chatters, to, body) do
    chatters
    |> Map.keys
    |> Enum.each(
      fn chatter ->
        send(String.to_atom(chatter), {:sendprivmsg, to, body})
        IO.puts("LOL, "<>inspect(chatter))
      end
    )
  end

end
