defmodule BitBucket do
  @moduledoc """
  BitBucket is the component which does the talking with the BitBucket API and
  any git parsing necessary.
  """

  import Git
  import BitBucket.OAuth2

  @web_base_url "https://bitbucket.org"

  # Components we have in this module:
  # * Request
  # * Issue / Pull Request / Repo level

  def repositories(owner) do
    resource = get_resource!("/repositories/" <> owner)
    resource |> Enum.map(fn(repo) -> repo["full_name"] end)
  end

  def pull_requests(repo, state \\ nil) do
    base_path = "/repositories/" <> repo <> "/pullrequests"

    path = if state do
        base_path <> "?" <> URI.encode_query(%{state: String.upcase(state)})
      else
        base_path
      end

    resource = get_resource!(path)

    resource
    |> Enum.map(fn(pr) ->
           %{id: pr["id"], title: pr["title"], url: pr["links"]["url"]}
         end)
  end

  def issues(repo, state \\ nil) do
    all_issues = get_resource!("/repositories/" <> repo <> "/issues")

    filtered_issues = if state == nil do
        all_issues
      else
        all_issues |> Enum.filter(fn(issue) -> issue["state"] == state end)
      end

    filtered_issues
    |> Enum.map(fn(issue) -> %{id: issue["id"], title: issue["title"]} end)
  end

  def create_pull_request(repo, title, source, dest \\ nil) do
    params = %{title: title, source: %{branch: %{name: source}}}

    if dest do
      params = params |> Dict.merge(destination: %{branch: %{name: dest}})
    end

    resp = post_resource!("/repositories/" <> repo <> "/pullrequests", params)

    resp.body
  end

  def create_issue(repo, title, kind \\ nil, content \\ nil, priority \\ nil) do
    params = %{title: title}

    if content, do: params = params |> Dict.merge(%{content: %{raw: content}})
    if kind, do: params = params |> Dict.merge(%{kind: kind})
    if priority, do: params = params |> Dict.merge(%{priority: priority})

    resp = post_resource!("/repositories/" <> repo <> "/issues", params)

    resp.body
  end

  def repo_names do
    remote_urls
      |> extract_repo_names
      |> Enum.filter(fn({k, v}) -> bitbucket_remote?(k, v) end)
  end

  def issue_url(repo, id) do
    category_url(repo, "issues", id)
  end

  def pull_request_url(repo, id) do
    category_url(repo, "pull-requests", id)
  end

  defp category_url(repo, category, id) do
    "#{@web_base_url}/#{repo}/#{category}/#{id}"
  end

  defp get_resource!(path) do
    token = oauth2_token
    resource = OAuth2.AccessToken.get!(token, path)
    resource.body["values"]
  end

  defp post_resource!(path, body) do
    token = oauth2_token
    OAuth2.AccessToken.post!(token, path, body)
  end

  defp put_resource!(path, body) do
    token = oauth2_token
    OAuth2.AccessToken.put!(token, path, body)
  end

  defp extract_repo_names(urls) do
    urls
    |> Enum.map(&Regex.replace(~r/^git@bitbucket.org:(.*).git$/, &1, "\\g{1}"))
    |> Enum.map(&Regex.replace(~r/^https:\/\/.+@bitbucket.org\/(.*).git$/, &1,
         "\\g{1}"))
  end

  defp bitbucket_remote?(section, value) do
    String.starts_with?(Atom.to_string(section), "remote") &&
      String.contains?(value[:url], "bitbucket.org")
  end
end
