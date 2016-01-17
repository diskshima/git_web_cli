defmodule GitLab do
  defstruct [:repo]

  import Git
  import GitLab.OAuth2

  def get_resource!(path) do
    token = oauth2_token
    resource = OAuth2.AccessToken.get!(token, path)
    resource.body
  end

  def project_id(gl) do
    [path, name] = gl.repo |> String.split("/")

    search_repo_name(name)
    |> Enum.filter(&(&1["namespace"]["path"] == path))
    |> Enum.at(0)
    |> Dict.get("id")
  end

  def search_repo_name(query) do
    token = oauth2_token
    get_resource!("/projects/search/" <> query)
  end

  defp extract_repo_names(urls) do
    urls
    |> Enum.map(&Regex.replace(~r/^git@bitbucket.org:(.*).git$/, &1, "\\g{1}"))
    |> Enum.map(&Regex.replace(~r/^https:\/\/.+@bitbucket.org\/(.*).git$/, &1,
         "\\g{1}"))
  end
end
