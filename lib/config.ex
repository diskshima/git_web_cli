defmodule Config do
  def gw_file do
    Path.expand("~/.gw")
  end

  def read do
    case File.read(gw_file) do
      {:ok, content} ->
        config_info = content |> Poison.decode!
        {:ok, config_info}
      {:error, reason} -> {:error, reason}
    end
  end

  def save(content) do
    converted = content |> Utils.stringify_keys
    new_content =
      case read do
        {:ok, existing} -> Dict.merge(existing, converted)
        {:error, _} -> content
      end

    json = Poison.encode!(new_content, [pretty: true])

    File.write(gw_file, json, [:write])
  end
end
