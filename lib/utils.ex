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

  def prompt_if_blank(value, _) when is_nil(value) == false do
    value
  end

  def prompt_if_blank(_, prompt_message) do
    IO.gets(prompt_message)
  end
end
