defmodule BitBucket do
  @moduledoc """
  BitBucket is the component which does the talking with the BitBucket API and
  any git parsing necessary.
  """

  defstruct [:repo]

  import Git
  import BitBucket.OAuth2

  def repositories(owner) do
    resource = get_resource!("/repositories/" <> owner)
    resource |> Enum.map(fn(repo) -> repo["full_name"] end)
  end

  def repo_names do
    remote_urls
    |> Enum.filter(&bitbucket_url?(&1))
    |> Git.extract_repo_names
  end

  def get_resource!(path) do
    token = oauth2_token
    resource = OAuth2.AccessToken.get!(token, path)
    resource.body["values"]
  end

  def post_resource!(path, body) do
    token = oauth2_token
    OAuth2.AccessToken.post!(token, path, body)
  end

  defp put_resource!(path, body) do
    token = oauth2_token
    OAuth2.AccessToken.put!(token, path, body)
  end

  defp bitbucket_url?(url) do
    String.contains?(url, "bitbucket.org")
  end
end
