defmodule IrckedElixir.Chatter do
  alias IrckedElixir.Chatter.Message, as: Message
  alias IrckedElixir.Chatter.Privmsg, as: Privmsg
  def start(server, port, nick) do
    {:ok, socket} = :gen_tcp.connect(to_charlist(server), port, [:binary, active: false])

    :gen_tcp.send(socket, ["USER ", nick, " 0 * :", nick, "\r\n"])
    :gen_tcp.send(socket, ["NICK ", nick, "\r\n"])

    run(socket)
  end
  def run(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    String.split(data, "\r\n") |> Enum.each(fn raw -> handle(Message.parse(raw), socket) end)
    run(socket)
  end
  def send(socket, to, body) do
    Privmsg.construct("functism", to, body).message |> Message.send(socket)
  end
  def handle(msg, socket) do
    case msg.command do
      "PING" -> Message.construct("", "PONG", msg.parameters) |> Message.send(socket)
      "001" -> Message.construct("", "JOIN", ["#qrs"]) |> Message.send(socket)
      "PRIVMSG" ->
        pm = Privmsg.parse(msg)
        IO.puts(inspect pm)
        case pm.body do
          ".bots" -> Privmsg.construct("functism", pm.to, "https://github.com/kurisufriend/ircked_elixir").message |> Message.send(socket)
          ".hello" -> Privmsg.construct("functism", pm.to, "hai").message |> Message.send(socket)
          _ -> ""
        end

      "" -> ""
      _ -> IO.puts(inspect msg)
    end
  end
end
