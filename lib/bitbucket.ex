defmodule BitBucket do
  @moduledoc """
  BitBucket is the component which does the talking with the BitBucket API and
  any git parsing necessary.
  """

  defstruct [:repo]

  import Git
  import BitBucket.OAuth2

  @web_base_url "https://bitbucket.org"

  def repositories(owner) do
    resource = get_resource!("/repositories/" <> owner)
    resource |> Enum.map(fn(repo) -> repo["full_name"] end)
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
    |> Enum.filter(&bitbucket_url?(&1))
    |> Git.extract_repo_names
  end

  def issue_url(repo, id) do
    category_url(repo, "issues", id)
  end

  def pull_request_url(repo, id) do
    category_url(repo, "pull-requests", id)
  end

  def get_resource!(path) do
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

  defp category_url(repo, category, id) do
    "#{@web_base_url}/#{repo}/#{category}/#{id}"
  end

  defp bitbucket_url?(url) do
    String.contains?(url, "bitbucket.org")
  end
end
