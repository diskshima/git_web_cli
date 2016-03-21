defmodule GitLab.OAuth2 do
  @moduledoc """
  Holds OAuth2 related functions for GitLab.
  """

  def oauth2_token do
    case existing_token do
      {:ok, token} ->
        token
        |> save_tokens
      _ ->
        client = oauth2_client

        input = IO.gets("Please specify GitLab username > ")

        username = input |> String.strip
        password = Utis.get_hidden_input("Please enter GitLab password " <>
          "(keys entered will be hidden) > ")
        params = Keyword.new([{:username, username}, {:password, password}])

        client
        |> OAuth2.Client.get_token!(params)
        |> save_tokens
    end
  end

  def host_name do
    case Config.read do
      {:ok, config} -> config["gitlab"]["host"]
      {:error, error} -> raise error
    end
  end

  def save_client_info(client_id, client_secret) do
    Config.save_key(:gitlab, %{client_id: client_id, client_secret: client_secret})
  end

  def read_client_info do
    values = Config.read_key(:gitlab)
    {values["client_id"], values["client_secret"]}
  end

  defp oauth2_client do
    {client_id, client_secret} = read_client_info

    OAuth2.Client.new([
      strategy: OAuth2.Strategy.Password,
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      site: "#{host_name}/api/v3",
      token_url: "#{host_name}/oauth/token",
      headers: [{"Accept", "application/json"},
        {"Content-Type", "application/json"}]
    ])
  end

  defp save_tokens(token) do
    gl_info = %{host: host_name, access_token: token.access_token,
      refresh_token: token.refresh_token, expires_at: token.expires_at}

    Config.save_key(:gitlab, gl_info)

    token
  end

  defp existing_token do
    case Config.read do
      {:ok, info} ->
        gl_config = info["gitlab"]
        expires = gl_config["expires_at"]
        refresh_token = gl_config["refresh_token"]

        cond do
          is_nil(refresh_token) -> {:no_token, nil}
          true ->
            {:ok, OAuth2.AccessToken.refresh!(
              %{refresh_token: refresh_token, client: oauth2_client})}
        end
      {:error, _} -> {:error, nil}
    end
  end
end
