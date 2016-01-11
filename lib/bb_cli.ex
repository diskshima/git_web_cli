defmodule BbCli do
  @moduledoc """
  Main module for the command line interface (CLI).
  It will parse the arguments and call into `BitBucket`.
  """

  def main(args) do
    args |> process
  end

  def process(args) do
    {subcommand, other_args} = args |> ListExt.pop

    case subcommand do
      "repos" -> process_repos(other_args)
      "pull-requests" -> process_pull_requests(other_args)
      "pull-request" -> process_pull_request(other_args)
      "issues" -> process_issues(other_args)
      "issue" -> process_issue(other_args)
      "open" -> open_in_browser(other_args)
      "reponame" -> BitBucket.repo_names |> print_results
      _ -> IO.puts "Invalid argument"
    end
  end

  defp get_repo_or_default(options) do
    options[:repo] || BitBucket.repo_names |> Enum.at(0)
  end

  defp print_results(list) do
    IO.puts Enum.join(list, "\r\n")
  end

  defp print_issue_result(issue_body) do
    msg = case issue_body do
          %{"error" => errors} ->
            errors["fields"]
            |> Enum.map(fn({_, messages}) -> messages |> Enum.join(", ") end)
            |> Enum.join("\n")
        _ -> "Created issue ##{issue_body["id"]}: #{issue_body["title"]}"
      end

    IO.puts(msg)
  end

  defp print_pullrequest_result(pr_body) do
    msg = case pr_body do
        %{"error" => errors} ->
          errors["fields"]
          |> Enum.map(fn({_, messages}) -> messages |> Enum.join(", ") end)
          |> Enum.join("\n")
        _ -> "Created pull request ##{pr_body["id"]}: #{pr_body["title"]}"
      end

    IO.puts(msg)
  end

  defp process_repos(other_args) do
    {options, _, _} = OptionParser.parse(other_args, switches: [username: :string])

    owner = options[:username]
    repos = BitBucket.repositories(owner)
    repos |> print_results
  end

  defp open_in_browser(other_args) do
    {options, args_left, _} = OptionParser.parse(other_args,
      switches: [repo: :string])

    {category, args_left2} = args_left |> ListExt.pop
    {id, _} = args_left2 |> ListExt.pop

    repo = get_repo_or_default(options)

    url = case category do
        "pull-request" -> BitBucket.pull_request_url(repo, id)
        "issue" -> BitBucket.issue_url(repo, id)
      end

    Launchy.open_url(url)
  end

  defp process_pull_requests(other_args) do
    {options, _, _} = OptionParser.parse(other_args,
      switches: [repo: :string, state: :string]
    )

    repo = get_repo_or_default(options)
    pulls = BitBucket.pull_requests(repo, options[:state])

    pulls
    |> Enum.sort_by(&Dict.get(&1, :id), &>=/2)
    |> Enum.map(fn(pr) -> "#{pr[:id]}: #{pr[:title]}" end)
    |> print_results
  end

  defp process_pull_request(other_args) do
    {options, _, _} = OptionParser.parse(other_args,
      switches: [repo: :string, title: :string, source: :string, target: :string]
    )

    repo = get_repo_or_default(options)
    source = options[:source] || Git.current_branch
    repo |> BitBucket.create_pull_request(options[:title], source,
         options[:target])
    |> print_pullrequest_result
  end

  defp process_issues(other_args) do
    {options, _, _} = OptionParser.parse(other_args,
      switches: [repo: :string, state: :string])

    repo = get_repo_or_default(options)
    issues = BitBucket.issues(repo, options[:state])

    issues
    |> Enum.sort_by(&Dict.get(&1, :id), &>=/2)
    |> Enum.map(fn(issue) -> "#{issue[:id]}: #{issue[:title]}" end)
    |> print_results
  end

   defp process_issue(other_args) do
    {options, _, _} = OptionParser.parse(other_args,
      switches: [title: :string, kind: :string, content: :string,
        priority: :string])
    repo = get_repo_or_default(options)
    issue_body = BitBucket.create_issue(repo, options[:title], options[:kind],
      options[:content], options[:priority])
    print_issue_result(issue_body)
  end
end
