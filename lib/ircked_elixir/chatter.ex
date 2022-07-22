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
  def handle(msg, socket) do
    case msg.command do
      "PING" -> Message.construct("", "PONG", msg.parameters) |> Message.send(socket)
      "001" -> Message.construct("", "JOIN", ["#qrs"]) |> Message.send(socket)
      "PRIVMSG" ->
        pm = Privmsg.parse(msg)
        IO.puts(inspect pm.message)
        Privmsg.construct("functism", pm.to, "hai").message |> Message.send(socket)
      "" -> ""
      _ -> IO.puts(inspect msg)
    end
  end
end
