defmodule BitBucket.OAuth2 do
  @moduledoc """
  Holds OAuth2 related functions for BitBucket.
  """

  def oauth2_token do
    case existing_token do
      {:ok, token} -> token
      _ ->
        client = oauth2_client

        input = IO.gets("Please specify BitBucket username > ")

        username = input |> String.strip
        password = Utils.get_hidden_input("Please enter BitBucket password " <>
          "(keys entered will be hidden) > ")
        params = Keyword.new([{:username, username}, {:password, password}])

        client
        |> OAuth2.Client.get_token!(params)
        |> save_tokens
    end
  end

  def save_client_info(client_id, client_secret) do
    Config.save_key(:bitbucket,
      %{client_id: client_id, client_secret: client_secret})
  end

  def read_client_info do
    values = Config.read_key(:bitbucket)
    {values["client_id"], values["client_secret"]}
  end

  defp oauth2_client do
    {client_id, client_secret} = read_client_info

    OAuth2.Client.new([
      strategy: OAuth2.Strategy.Password,
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      site: "https://api.bitbucket.org/2.0",
      token_url: "https://bitbucket.org/site/oauth2/access_token",
      headers: [{"Accept", "application/json"},
        {"Content-Type", "application/json"}]
    ])
  end

  defp save_tokens(token) do
    bb_info = %{access_token: token.access_token,
      refresh_token: token.refresh_token, expires_at: token.expires_at}

    Config.save_key(:bitbucket, bb_info)

    token
  end

  defp existing_token do
    case Config.read do
      {:ok, info} ->
        bb_config = info["bitbucket"]
        if bb_config["expires_at"] < OAuth2.Util.unix_now do
          {:ok, OAuth2.AccessToken.refresh!(
            %{refresh_token: bb_config["refresh_token"], client: oauth2_client})}
        else
          {:ok, OAuth2.AccessToken.new(bb_config["access_token"], oauth2_client)}
        end
      {:error, _} -> {:error, nil}
    end
  end
end
