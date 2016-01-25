defmodule GitLab.OAuth2 do
  @moduledoc """
  Holds OAuth2 related functions for GitLab.
  """

  @client_id "YOUR_CLIENT_ID"
  @client_secret "YOUR_CLIENT_SECRET"

  def oauth2_token do
    case existing_token do
      {:ok, token} ->
        token
        |> save_tokens
      _ ->
        client = oauth2_client

        input = IO.gets("Please specify GitLab username > ")

        username = input |> String.strip
        password = get_hidden_input("Please enter GitLab password " <>
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

  defp oauth2_client do
    OAuth2.Client.new([
      strategy: OAuth2.Strategy.Password,
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      site: "#{host_name}/api/v3",
      token_url: "#{host_name}/oauth/token",
      headers: [{"Accept", "application/json"},
        {"Content-Type", "application/json"}]
    ])
  end

  def get_hidden_input(prompt) do
    IO.write prompt
    :io.setopts(echo: false)
    password = String.strip(IO.gets(""))
    :io.setopts(echo: true)
    password
  end

  defp save_tokens(token) do
    gl_info = %{gitlab: %{host: host_name, access_token: token.access_token,
      refresh_token: token.refresh_token, expires_at: token.expires_at}}

    Config.save(gl_info)

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