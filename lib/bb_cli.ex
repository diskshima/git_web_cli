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
        BitBucket.repositories(owner) |> print_results
      "reponame" ->
        BitBucket.repo_names |> print_results
      _ ->
        IO.puts "Invalid argument"
    end
  end

  defp print_results(list) do
    IO.puts Enum.join(list, "\r\n")
  end

end
