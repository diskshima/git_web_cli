defmodule GitLab do
  @moduledoc """
  GitLab is the component which does the talking with the GitLab API and
  any git parsing necessary.
  """

  defstruct [:repo]

  import Git
  import GitLab.OAuth2

  def repo_names do
    remote_urls
    |> Git.extract_repo_names
  end

  def get_resource!(path) do
    token = oauth2_token
    resource = OAuth2.AccessToken.get!(token, path)
    resource.body
  end

  def post_resource!(path, body) do
    token = oauth2_token
    OAuth2.AccessToken.post!(token, path, body)
  end

  def project_id(gitlab) do
    [path, name] = gitlab.repo |> String.split("/")

    search_repo_name(name)
    |> Enum.filter(&(&1["namespace"]["path"] == path))
    |> Enum.at(0)
    |> Dict.get("id")
  end

  def search_repo_name(query) do
    get_resource!("/projects/search/" <> query)
  end
end
