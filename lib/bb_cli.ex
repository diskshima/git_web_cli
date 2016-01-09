defmodule BbCli do
  def main(args) do
    args |> process
  end

  def process(args) do
    subcommand = Enum.at(args, 0)
    other_args = Enum.drop(args, 1)

    {options, _, _} = OptionParser.parse(other_args,
      switches: [username: :string, repo: :string, title: :string,
                 source: :string, target: :string]
    )

    case subcommand do
      "repos" ->
        owner = options[:username]
        BitBucket.repositories(owner) |> print_results
      "pull-requests" ->
        repo = get_repo_or_default(options)
        BitBucket.pull_requests(repo)
          |> Enum.sort_by(&Dict.get(&1, :id), &>=/2)
          |> Enum.map(fn(pr) -> "#{pr[:id]}: #{pr[:title]}" end)
          |> print_results
      "pull-request" ->
        # Create a pull request
        repo = get_repo_or_default(options)
        source = options[:source] || BitBucket.current_branch
        repo
        |> BitBucket.create_pull_request(options[:title], source,
             options[:target])
        |> print_pullrequest_result
      "issues" ->
        repo = get_repo_or_default(options)
        BitBucket.issues(repo)
          |> Enum.sort_by(&Dict.get(&1, :id), &>=/2)
          |> Enum.map(fn(issue) -> "#{issue[:id]}: #{issue[:title]}" end)
          |> print_results
      "issue" ->
        repo = get_repo_or_default(options)
        issue = BitBucket.create_issue(repo, options[:title])
        IO.puts "Created issue ##{issue.id}: #{issue.title}"
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

  defp print_pullrequest_result(pr_body) do
    msg = case pr_body do
        %{"error" => errors} ->
          errors["fields"]
          |> Enum.map(fn({field, messages}) -> messages |> Enum.join(", ") end)
          |> Enum.join("\n")
        _ -> "Created pull request ##{pr_body.id}: #{pr_body.title}"
      end

    IO.puts(msg)
  end
end
