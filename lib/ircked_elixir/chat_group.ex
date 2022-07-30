defmodule IrckedElixir.ChatGroup do
  use GenServer

  alias IrckedElixir.Chatter.Message, as: Message
  alias IrckedElixir.Chatter.Privmsg, as: Privmsg

  @server_address "localhost"
  @server_port 6667
  @base_nick "functism"
  @chatters 20
  @ascii_base_path "/path/to/ascii/"

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
          ".play "<>cmd -> play(chatters, pm.to, @ascii_base_path<>cmd<>".txt")
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

  def play(_chatters, to, path) do
    IO.puts(path)
    {code, asskey} = File.read(path)
    case code do
      :ok ->
        asskey
        |> String.split("\n")
        |> Stream.with_index |> Enum.to_list
        |> Enum.each(
          fn line ->
            GenServer.call(
              (@base_nick<>to_string(rem(elem(line, 1), @chatters)+1)) |> String.to_atom,
              {:sendprivmsg, to, elem(line, 0)}
            )
          end
          )
      _ -> send(String.to_atom(@base_nick<>"1"), {:sendprivmsg, to, "asskey not found :D"})
    end

  end

  def send_all(chatters, to, body) do
    chatters
    |> Map.keys
    |> Enum.each(
      fn chatter ->
        GenServer.call(String.to_atom(chatter), {:sendprivmsg, to, body})
        IO.puts("LOL, "<>inspect(chatter))
      end
    )
  end

end
