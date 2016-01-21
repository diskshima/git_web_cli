defmodule GitLab do
  defstruct [:repo]

  import Git
  import GitLab.OAuth2

  def get_resource!(path) do
    token = oauth2_token
    resource = OAuth2.AccessToken.get!(token, path)
    resource.body
  end

  def post_resource!(path, body) do
    token = oauth2_token
    OAuth2.AccessToken.post!(token, path, body)
  end

  def project_id(gl) do
    [path, name] = gl.repo |> String.split("/")

    search_repo_name(name)
    |> Enum.filter(&(&1["namespace"]["path"] == path))
    |> Enum.at(0)
    |> Dict.get("id")
  end

  def search_repo_name(query) do
    get_resource!("/projects/search/" <> query)
  end

  def repo_names do
    remote_urls
    |> Git.extract_repo_names
  end
end
