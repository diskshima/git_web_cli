defmodule BbCli do
  def main(args) do
    args |> process
  end

  def process(args) do
    subcommand = Enum.at(args, 0)
    other_args = Enum.drop(args, 1)

    {options, _, _} = OptionParser.parse(other_args,
      switches: [username: :string, repo: :string]
    )

    case subcommand do
      "repos" ->
        owner = options[:username]
        BitBucket.repositories(owner) |> print_results
      "pullrequests" ->
        repo = get_repo_or_default(options)
        BitBucket.pullrequests(repo)
          |> Enum.sort_by(&Dict.get(&1, :id), &>=/2)
          |> Enum.map(fn(pr) -> "#{pr[:id]}: #{pr[:title]}" end)
          |> print_results
      "issues" ->
        repo = get_repo_or_default(options)
        BitBucket.issues(repo)
          |> Enum.sort_by(&Dict.get(&1, :id), &>=/2)
          |> Enum.map(fn(issue) -> "#{issue[:id]}: #{issue[:title]}" end)
          |> print_results
      "reponame" ->
        BitBucket.repo_names |> print_results
      _ ->
        IO.puts "Invalid argument"
    end
  end

  defp get_repo_or_default(options) do
    options[:repo] || BitBucket.repo_names |> Enum.at(0)
  end

  defp print_results(list) do
    IO.puts Enum.join(list, "\r\n")
  end

end
