defmodule BbCli do
  def main(args) do
    args |> process
  end

  def process(args) do
    subcommand = Enum.at(args, 0)
    other_args = Enum.drop(args, 1)

    {options, _, _} = OptionParser.parse(other_args,
      switches: [username: :string],
    )

    case subcommand do
      "repos" ->
        owner = options[:username]
        IO.puts BitBucket.repositories(owner) |> Enum.join("\r\n")
      _ ->
        IO.puts "Invalid argument"
    end
  end
end
