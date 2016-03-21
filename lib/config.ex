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

  def read_key(key) when is_atom(key) do
    read_key(Atom.to_string(key))
  end

  def read_key(key) do
    case read do
      {:ok, content} -> content[key]
      {:error, reason} -> raise "Failed to retrieve key."
    end
  end

  def save_key(key, content) when is_atom(key) do
    save_key(Atom.to_string(key), content)
  end

  def save_key(key, content) do
    converted = content |> Utils.stringify_keys

    new_content =
      case read do
        {:ok, existing} ->
          values = Dict.merge(existing[key], converted)
          Map.put(existing, key, values)
        {:error, _} -> content
      end

    json = Poison.encode!(new_content, [pretty: true])

    File.write(gw_file, json, [:write])
  end
end
