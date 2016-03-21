defmodule GitHub do
  @moduledoc """
  GitHub is the component which does the talking with the GitHub API and
  any git parsing necessary.
  """

  defstruct [:repo]

  import Git
  import GitHub.OAuth2

  def repo_names do
    remote_urls
    |> Enum.filter(&github_url?(&1))
    |> Git.extract_repo_names
  end

  def get_resource!(path, params \\ nil) do
    token = oauth2_token

    opts = if params, do: [params: params], else: []

    OAuth2.AccessToken.get!(token, path, [], opts)
  end

  def post_resource!(path, body) do
    token = oauth2_token
    OAuth2.AccessToken.post!(token, path, body)
  end

  def put_resource!(path, body) do
    token = oauth2_token
    OAuth2.AccessToken.put!(token, path, body)
  end

  def patch_resource!(path, body) do
    token = oauth2_token
    OAuth2.AccessToken.patch!(token, path, body)
  end

  def delete!(path) do
    token = oauth2_token
    resource = OAuth2.AccessToken.delete!(token, path)
    resource.body
  end

  defp github_url?(url) do
    String.contains?(url, "github.com")
  end
end
