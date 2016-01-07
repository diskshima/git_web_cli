defmodule BitBucket do
  @client_id "3CP8yrCLzv9UWkpdQ6"
  @client_secret "YrSSB5LzQrzp5jQatQ9FRMTNwPcBhEVC"

  def repositories(owner) do
    token = oauth2_token
    resource = OAuth2.AccessToken.get!(token, "/repositories/" <> owner)

    body = resource.body

    body["values"]
    |> Enum.map(fn(repo) -> repo["full_name"] end)
  end

  def repo_names do
    extract_remote_urls |> extract_repo_names
  end

  defp extract_repo_names(urls) do
    urls
      |> Enum.map(&Regex.replace(~r/^git@bitbucket.org:(.*).git$/, &1, "\\g{1}"))
    # TODO Add HTTPS endpoint support
  end

  defp extract_remote_urls do
    read_git_config
      |> Enum.filter(fn({k, v}) -> bitbucket_remote?(k, v) end)
      |> Enum.map(fn({_, v}) -> v[:url] end)
  end

  defp bitbucket_remote?(section, value) do
    String.starts_with?(Atom.to_string(section), "remote") &&
      String.contains?(value[:url], "bitbucket.org")
  end

  defp read_git_config do
    {:ok, gitconfig_file} = File.read(".git/config")
    Ini.decode(gitconfig_file)
  end

  defp oauth2_client do
    OAuth2.Client.new([
      strategy: OAuth2.Strategy.Password,
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      site: "https://api.bitbucket.org/2.0",
      token_url: "https://bitbucket.org/site/oauth2/access_token",
    ])
  end

  def oauth2_token do
    case existing_token do
      {:ok, token} -> token
      _ ->
        client = oauth2_client

        username = IO.gets("Please specify BitBucket username > ") |> String.strip
        password = get_hidden_input("Please enter BitBucket password (keys entered will be hidden) > ")
        params = Keyword.new([{:username, username}, {:password, password}])

        client
          |> OAuth2.Client.put_header("Content-Type", "application/json")
          |> OAuth2.Client.get_token!(params)
          |> save_tokens
    end
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

    json = Poison.encode!(tokens)

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
