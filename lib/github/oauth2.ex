defmodule GitHub.OAuth2 do
  @moduledoc """
  Holds OAuth2 related functions for GitLab.
  """

  @client_id "YOUR_CLIENT_ID"
  @client_secret "YOUR_CLIENT_SECRET"

  def oauth2_token do
    case existing_token do
      {:ok, token} -> token
      _ ->
        client = oauth2_client

        input = IO.gets("Please specify GitHub username > ")

        username = input |> String.strip
        password = Utils.get_hidden_input("Please enter GitHub password " <>
          "(keys entered will be hidden) > ")

        token = create_auth(username, password)

        if token do
          token |> save_tokens
        else
          raise "Errored obtaining token."
        end
    end
  end

  defp create_auth(username, password) do
    hackney_opts = [basic_auth: {username, password}]
    params = Poison.encode!(%{"client_secret": @client_secret, scopes: ["repo"]})

    response = HTTPoison.put!(
      "https://api.github.com/authorizations/clients/#{@client_id}", params,
      [{"Accept", "application/json"}, {"Content-Type", "application/json"}],
      [ hackney: hackney_opts ])

    otp_required = response.headers
    |> Enum.find(fn(x) -> elem(x, 0) == "X-GitHub-OTP" end)
    |> elem(1) |> String.contains?("required")

    if otp_required do
      two_factor_input = IO.gets("Two Factor is enabled. Please enter your GitHub two"
        <> " factor code > ")
      two_factor = two_factor_input |> String.strip
      response = HTTPoison.put!(
        "https://api.github.com/authorizations/clients/#{@client_id}", params,
        [{"Accept", "application/json"}, {"Content-Type", "application/json"},
         {"X-GitHub-OTP", two_factor}],
        [ hackney: hackney_opts ])
    end

    # TODO Deal with error
    #   Save it properly or ask user to manually revoke it.
    body = Poison.decode!(response.body)
    token_params = %{"access_token" => body["token"], "token_type" => "token"}

    OAuth2.AccessToken.new(token_params, oauth2_client)
  end

  defp oauth2_client do
    OAuth2.Client.new([
      strategy: OAuth2.Strategy.Password,
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri: "http://example.com/",
      site: "https://api.github.com",
      authorize_url: "https://github.com/login/oauth/authorize",
      token_url: "https://github.com/login/oauth/access_token",
      headers: [{"Accept", "application/json"},
        {"Content-Type", "application/json"}],
      scope: "repo"
    ])
  end

  defp save_tokens(token) do
    if token.access_token do
      info = %{github: %{access_token: token.access_token}}
      Config.save(info)
    end

    token
  end

  defp existing_token do
    case Config.read do
      {:ok, info} ->
        config = info["github"]
        if config do
          {:ok, OAuth2.AccessToken.new(config["access_token"], oauth2_client)}
        else
          {:error, nil}
        end
      {:error, _} -> {:error, nil}
    end
  end
end
