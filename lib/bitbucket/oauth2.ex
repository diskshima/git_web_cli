defmodule BitBucket.OAuth2 do
  @moduledoc """
  Holds OAuth2 related functions.
  Including token saving as well.

  NOTE May move token saving into another separate module as it may potentially
       grow into a more generic config persistence component.
  """

  @client_id "YOUR_CLIENT_ID"
  @client_secret "YOUR_CLIENT_SECRET"

  def oauth2_token do
    case existing_token do
      {:ok, token} -> token
      _ ->
        client = oauth2_client

        input = IO.gets("Please specify BitBucket username > ")

        username = input |> String.strip
        password = get_hidden_input("Please enter BitBucket password " <>
          "(keys entered will be hidden) > ")
        params = Keyword.new([{:username, username}, {:password, password}])

        client
        |> OAuth2.Client.get_token!(params)
        |> save_tokens
    end
  end

  defp oauth2_client do
    OAuth2.Client.new([
      strategy: OAuth2.Strategy.Password,
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      site: "https://api.bitbucket.org/2.0",
      token_url: "https://bitbucket.org/site/oauth2/access_token",
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
    tokens = %{access_token: token.access_token,
      refresh_token: token.refresh_token, expires_at: token.expires_at}

    json = Poison.encode!(tokens, [pretty: true])

    File.write(bb_cli_file, json, [:write])
    token
  end

  defp bb_cli_file do
    Path.expand("~/.bb_cli")
  end

  defp existing_token do
    case read_tokens do
      {:ok, info} ->
        if info["expires_at"] < OAuth2.Util.unix_now do
          {:ok, OAuth2.AccessToken.refresh!(
            %{refresh_token: info["refresh_token"], client: oauth2_client})}
        else
          {:ok, OAuth2.AccessToken.new(info["access_token"], oauth2_client)}
        end
      {:error, _} -> {:error, nil}
    end
  end

  defp read_tokens do
    case File.read(bb_cli_file) do
      {:ok, content} ->
        token_info = content |> Poison.decode!
        {:ok, token_info}
      {:error, reason} -> {:error, reason}
    end
  end
end
