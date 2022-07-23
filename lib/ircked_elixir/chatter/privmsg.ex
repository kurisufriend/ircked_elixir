defmodule IrckedElixir.Chatter.Privmsg do
  defstruct message: %IrckedElixir.Chatter.Message{}, from: "", to: "", body: ""
  def parse(message) do
    %IrckedElixir.Chatter.Privmsg{message: message, from: String.slice(message.prefix, 1..999), to: Enum.at(message.parameters, 0), body: Enum.join(Enum.slice(message.parameters, 1..999), " ") |> String.slice(1..999)}
  end
  def construct(from, to, body) do
    %IrckedElixir.Chatter.Privmsg{message: %IrckedElixir.Chatter.Message{prefix: ":"<>from, command: "PRIVMSG", parameters: ([] |> List.insert_at(0, to)) ++ String.split(":"<>body, " ")}, from: from, to: to, body: body}
  end
end
