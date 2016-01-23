defmodule Utils do
  def stringify_keys(dict) when is_map(dict) do
    dict
    |> Dict.to_list
    |> stringify_keys
    |> Enum.into(%{})
  end

  def stringify_keys(tuples) when is_list(tuples) do
    tuples |> Enum.map(
      fn(tuple) -> {elem(tuple, 0) |> Atom.to_string, elem(tuple, 1)} end)
  end
end
