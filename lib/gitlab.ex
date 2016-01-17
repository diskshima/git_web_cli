defmodule GitLab do
  defstruct [:repo]

  import Git
  import GitLab.OAuth2

  def get_resource!(path) do
    token = oauth2_token
    resource = OAuth2.AccessToken.get!(token, path)
    resource.body
  end

  def project_id do
  end
end
