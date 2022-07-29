defmodule IrckedElixir.Chatter do
  use GenServer

  alias IrckedElixir.Chatter.Message, as: Message
  alias IrckedElixir.Chatter.Privmsg, as: Privmsg

  @impl true
  def init(starting_state) do
    {:ok, socket} = :gen_tcp.connect(to_charlist(starting_state.ip), starting_state.port, [:binary, active: true])
    starting_state = %{starting_state | sock: socket}
    :gen_tcp.send(socket, ["USER ", starting_state.nick, " 0 * :", starting_state.nick, "\r\n"])
    :gen_tcp.send(socket, ["NICK ", starting_state.nick, "\r\n"])

    send(:chatgroup, {:checkin, starting_state.nick, self()})
    {:ok, starting_state}
  end

  @impl true
  def handle_info({:tcp, _, data}, state) do
    String.split(data, "\r\n") |> Enum.each(fn raw -> handle(Message.parse(raw), state) end)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:sendprivmsg, to, body}, state) do
    Privmsg.construct(state.nick, to, body).message |> Message.send(state.sock)
    {:noreply, state}
  end

  @impl true
  def handle_call({:sendprivmsg, to, body}, _, state) do
    Privmsg.construct(state.nick, to, body).message |> Message.send(state.sock)
    Process.sleep(10)
    {:reply, :ok, state}
  end

  def start_link(starting_state) do
    GenServer.start_link(__MODULE__, starting_state, name: starting_state.nick |> String.to_atom)
  end

  def sendpm(to, body) do
    send(self(), {:sendprivmsg, to, body})
  end

  def run(state) do
    {:ok, data} = :gen_tcp.recv(state.sock, 0)
    String.split(data, "\r\n") |> Enum.each(fn raw -> handle(Message.parse(raw), state) end)
    run(state)
  end

  def handle(msg, state) do
    if state.reporter do
      send(:chatgroup, {:report, msg})
    end
    case msg.command do
      "PING" -> Message.construct("", "PONG", msg.parameters) |> Message.send(state.sock)
      "001" -> Message.construct("", "JOIN", ["#qrs"]) |> Message.send(state.sock)
      "PRIVMSG" ->
        pm = Privmsg.parse(msg)
        case pm.body do
          _ -> ""
        end

      "" -> ""
      _ -> ""
    end
  end
end
