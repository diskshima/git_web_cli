defprotocol ListExt do
  def pop(list)
end

defimpl ListExt, for: List do
  def pop(list) do
    item = list |> List.first

    rest = if item do
        list |> Enum.drop(1)
      else
        []
      end

    {item, rest}
  end
end
