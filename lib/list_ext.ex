defprotocol ListExt do
  def pop(list)
  def pop(list, count)
end

defimpl ListExt, for: List do
  def pop(list) do
    pop(list, 1)
  end

  def pop(list, count) do
    pop_in(list, count, {})
  end

  defp pop_in(list, 0, acc) do
    Tuple.append(acc, list)
  end

  defp pop_in(list, count, acc) do
    item = list |> List.first

    rest = if item do
        list |> Enum.drop(1)
      else
        []
      end

    pop_in(rest, count - 1, Tuple.append(acc, item))
  end
end
