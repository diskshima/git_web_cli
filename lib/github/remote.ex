defimpl Remote, for: GitHub do
  def issues(remote, state \\ nil) do
    base_path = "/repos/#{remote.repo}/issues"

    path = if state do
        query_string = URI.encode_query(%{state: state})
        "#{base_path}?#{query_string}"
      else
        base_path
      end

    values = aggregate_results(path, [])

    values
    |> Enum.map(&to_simple_pr(&1))
  end

  defp to_simple_pr(pr) do
    %{id: pr["number"], title: pr["title"]}
  end

  defp aggregate_results(nil, values) do
    values
  end

  defp aggregate_results(url, values) do
    resource = GitHub.get_resource!(url)

    values = values ++ resource.body

    next_url = try_extract_link(resource)

    aggregate_results(next_url, values)
  end

  defp try_extract_link(resource) do
    link_value = resource.headers |> Utils.find_header("Link")

    if link_value do
      link_header = ExLinkHeader.parse!(link_value)
      link_header["next"][:url]
    else
      nil
    end
  end
end
