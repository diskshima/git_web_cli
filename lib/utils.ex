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

  def find_header(headers, key) do
    case headers |> Enum.find(fn {k, _} -> k == key end) do
      {_, v} -> v
      _ -> nil
    end
  end

  def get_hidden_input(prompt) do
    IO.write prompt
    :io.setopts(echo: false)
    password = String.strip(IO.gets(""))
    :io.setopts(echo: true)
    IO.puts("")
    password
  end

  defmacro contained_case(value, do: lines) do
    new_lines = Enum.map(lines, fn ({:->, context, [[list], result]}) ->
        condition = quote do: Enum.member?(unquote(list), unquote(value))
        {:->, context, [[condition], result]}
      end)

    # base_case = quote do: (true -> nil)
    # new_lines = new_lines ++ base_case

    quote do
      cond do
        unquote(new_lines)
      end
    end
  end
end
