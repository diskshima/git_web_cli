defmodule BitBucket do
  use HTTPoison.Base

  def process_url(url) do
    "https://api.bitbucket.org/2.0" <> url
  end

  def process_response_body(body) do
    body
    |> Poison.decode!
  end

  def repositories(owner) do
    body = get!("/repositories/" <> owner).body

    body["values"]
    |> Enum.map(fn(repo) -> repo["full_name"] end)
  end
end
