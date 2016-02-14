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

    remote = get_remote(other_args)

    cond do
      ~w(pull-requests prs) |> Enum.member?(subcommand) ->
        process_pull_requests(remote, other_args)
      ~w(pull-request pr) |> Enum.member?(subcommand) ->
        process_pull_request(remote, other_args)
      ~w(issues is) |> Enum.member?(subcommand) ->
        process_issues(remote, other_args)
      ~w(issue i) |> Enum.member?(subcommand) ->
        process_issue(remote, other_args)
      ~w(open o) |> Enum.member?(subcommand) ->
        open_in_browser(remote, other_args)
      ~w(close cl) |> Enum.member?(subcommand) ->
        process_close(remote, other_args)
      true -> IO.puts "Invalid argument"
    end
  end

  defp get_repo_or_default(options) do
    if options[:repo] do
      options[:repo]
    else
      case determine_remote_type do
        :bitbucket -> BitBucket.repo_names |> Enum.at(0)
        :gitlab -> GitLab.repo_names |> Enum.at(0)
      end
    end
  end

  defp print_results(list) do
    IO.puts Enum.join(list, "\r\n")
  end

  defp print_issue_result(issue_body, verb) do
    msg = case issue_body do
        %{id: id, title: title} -> "#{verb} issue ##{id}: #{title}"
        %{error: message} -> message
      end

    IO.puts(msg)
  end

  defp print_pullrequest_result(pr_body) do
    msg = case pr_body do
        %{id: id, title: title} -> "Created pull request ##{id}: #{title}"
        %{error: message} -> message
      end

    IO.puts(msg)
  end

  defp open_in_browser(remote, other_args) do
    {_, args_left, _} = OptionParser.parse(other_args,
      switches: [repo: :string])

    {category, args_left2} = args_left |> ListExt.pop
    {id, _} = args_left2 |> ListExt.pop

    url = cond do
        ~w(pull-request pr) |> Enum.member?(category) ->
          remote |> Remote.pull_request_url(id)
        ~w(issue i) |> Enum.member?(category) ->
          remote |> Remote.issue_url(id)
      end

    Launchy.open_url(url)
  end

  defp process_pull_requests(remote, other_args) do
    {options, _, _} = OptionParser.parse(other_args,
      switches: [repo: :string, state: :string]
    )

    pulls = remote |> Remote.pull_requests(options[:state])

    pulls
    |> Enum.sort_by(&Dict.get(&1, :id), &>=/2)
    |> Enum.map(fn(pr) -> "#{pr[:id]}: #{pr[:title]}" end)
    |> print_results
  end

  defp process_pull_request(remote, other_args) do
    {options, _, _} = OptionParser.parse(other_args,
      switches: [repo: :string, title: :string, source: :string, target: :string, r: :boolean]
    )

    title = Utils.prompt_if_blank(options[:title], 'Enter issue title > ')
    source = options[:source] || Git.current_branch

    remote
    |> Remote.create_pull_request(title, source, options[:target],
         remove_source_branch: options[:r])
    |> print_pullrequest_result
  end

  defp process_issues(remote, other_args) do
    {options, _, _} = OptionParser.parse(other_args,
      switches: [state: :string])

    issues = remote |> Remote.issues(options[:state])

    issues
    |> Enum.sort_by(&Dict.get(&1, :id), &>=/2)
    |> Enum.map(fn(issue) -> "#{issue[:id]}: #{issue[:title]}" end)
    |> print_results
  end

   defp process_issue(remote, other_args) do
    {options, _, _} = OptionParser.parse(other_args,
      switches: [title: :string, description: :string, kind: :string,
        priority: :string, labels: :string])

    title = Utils.prompt_if_blank(options[:title], 'Enter pull request title > ')
    other_opts = options |> Dict.drop([:title])

    remote
    |> Remote.create_issue(title, other_opts)
    |> print_issue_result("Created")
  end

  defp process_close(remote, other_args) do
    {_, args_left, _} = OptionParser.parse(other_args)

    {category, args_left2} = args_left |> ListExt.pop
    {id, _} = args_left2 |> ListExt.pop

    cond do
      # ~w(pull-request pr) |> Enum.member?(category) ->
      #   remote |> Remote.close_pull_request(id)
      ~w(issue i) |> Enum.member?(category) ->
        remote
        |> Remote.close_issue(id)
        |> print_issue_result("Closed")
    end
  end

  def get_remote(options) do
    repo = get_repo_or_default(options)

    case determine_remote_type do
      :bitbucket -> %BitBucket{repo: repo}
      :gitlab -> %GitLab{repo: repo}
      _ -> raise "No remote found."
    end
  end

  defp determine_remote_type do
    remotes = Git.remote_urls

    is_bb =
      remotes
      |> Enum.any?(fn(url) -> String.contains?(url, "bitbucket.org") end)

    if is_bb, do: :bitbucket, else: :gitlab
  end
end
