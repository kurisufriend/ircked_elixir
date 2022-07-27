defmodule IrckedElixir.Chatter do
  use GenServer

  alias IrckedElixir.Chatter.Message, as: Message
  alias IrckedElixir.Chatter.Privmsg, as: Privmsg

  @impl true
  def init(starting_state) do
    {:ok, socket} = :gen_tcp.connect(to_charlist(starting_state.ip), starting_state.port, [:binary, active: false])
    IO.puts(inspect starting_state)
    starting_state = %{starting_state | sock: socket}
    IO.puts(inspect starting_state)
    IO.puts(inspect socket)
    :gen_tcp.send(socket, ["USER ", starting_state.nick, " 0 * :", starting_state.nick, "\r\n"])
    :gen_tcp.send(socket, ["NICK ", starting_state.nick, "\r\n"])

    send(self(), {:run, starting_state})
    {:ok, starting_state}
  end

  @impl true
  def handle_info({:sendmsg, to, body}, state) do
    Privmsg.construct(state.nick, to, body).message |> Message.send(state.sock)
    {:noreply, state}
  end

  @impl true
  def handle_info({:run, start_state}, _state) do
    run(start_state)
    {:noreply, start_state}
  end

  def start_link(starting_state) do
    GenServer.start_link(__MODULE__, starting_state)
  end

  def sendmsg(to, body) do
    send(self(), {:sendmsg, to, body})
  end

  def run(state) do
    {:ok, data} = :gen_tcp.recv(state.sock, 0)
    String.split(data, "\r\n") |> Enum.each(fn raw -> handle(Message.parse(raw), state) end)
    run(state)
  end

  def handle(msg, state) do
    case msg.command do
      "PING" -> Message.construct("", "PONG", msg.parameters) |> Message.send(state.sock)
      "001" -> Message.construct("", "JOIN", ["#qrs"]) |> Message.send(state.sock)
      "PRIVMSG" ->
        pm = Privmsg.parse(msg)
        IO.puts(inspect pm)
        case pm.body do
          ".bots" -> Privmsg.construct("functism", pm.to, "https://github.com/kurisufriend/ircked_elixir").message |> Message.send(state.sock)
          ".hello" -> Privmsg.construct("functism", pm.to, "hai").message |> Message.send(state.sock)
          _ -> ""
        end

      "" -> ""
      _ -> IO.puts(inspect msg)
    end
  end
end
