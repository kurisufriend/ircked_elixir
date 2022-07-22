defmodule IrckedElixir.Chatter.Message do
  defstruct prefix: "", command: "", parameters: []
  def parse(raw) do
    parts = String.split(raw, " ")

    is_prefix = String.starts_with?(Enum.at(parts, 0), ":")

    pre = if(is_prefix, [do: Enum.at(parts, 0), else: ""])
    comm = if(is_prefix, [do: Enum.at(parts, 1), else: Enum.at(parts, 0)])
    param = if(is_prefix, [do: Enum.slice(parts, 2..999), else: Enum.slice(parts, 1..999)])
    %IrckedElixir.Chatter.Message{prefix: pre, command: comm, parameters: param}
  end
  def construct(prefix, command, parameters) do
    %IrckedElixir.Chatter.Message{prefix: prefix, command: command, parameters: parameters}
  end
  def send(msg, socket) do
    :gen_tcp.send(socket, [if(msg.prefix == "", [do: "", else: msg.prefix<>" "]), msg.command, " ", Enum.join(msg.parameters, " "), "\r\n"])
    IO.puts([if(msg.prefix == "", [do: "", else: msg.prefix<>" "]), msg.command, " ", Enum.join(msg.parameters, " "), "\r\n"])
  end
end
