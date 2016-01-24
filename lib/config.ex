defmodule Config do
  def bb_cli_file do
    Path.expand("~/.bb_cli")
  end

  def read do
    case File.read(bb_cli_file) do
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

    File.write(bb_cli_file, json, [:write])
  end
end
