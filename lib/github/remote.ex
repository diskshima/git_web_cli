defimpl Remote, for: GitHub do
  def issues(remote, state \\ nil) do
    base_path = issues_path(remote)
    path = if state do
        query_string = URI.encode_query(%{state: state})
        "#{base_path}?#{query_string}"
      else
        base_path
      end

    values = aggregate_results(path, [])

    values
    |> Enum.map(&extract_id_title(&1))
  end

  def issue_url(remote, id) do
    remote |> category_url("issues", id)
  end

  def pull_request_url(remote, number) do
    remote |> category_url("pull", number)
  end

  def get_issue(remote, number, _) do
    path = issue_path(remote, number)
    resp = GitHub.get_resource!(path, nil)
    handle_response(resp.body)
  end

  def create_issue(remote, title, options \\ %{}) do
    params = %{title: title}

    if options |> Dict.has_key?(:description) do
      params = params |> Dict.put_new(:body, options[:description])
    end

    if options |> Dict.has_key?(:labels) do
      params = params |> Dict.merge(%{labels: options[:labels]})
    end

    resp = GitHub.post_resource!(issues_path(remote), params)

    handle_response(resp.body)
  end

  def close_issue(remote, number) do
    path = issue_path(remote, number)
    params = %{state: "closed"}
    resp = GitHub.patch_resource!(path, params)
    handle_response(resp.body)
  end

  def pull_requests(remote, state \\ nil) do
    base_path = pulls_path(remote)

    path = if state do
        query_string = URI.encode_query(%{state: state})
        "#{base_path}?#{query_string}"
      else
        base_path
      end

    values = aggregate_results(path, [])

    values |> Enum.map(&extract_id_title(&1))
  end

  def create_pull_request(remote, title, source, dest, _options) do
    path = pulls_path(remote)

    dest = dest || "master"
    params = %{title: title, head: source, base: dest}

    resp = GitHub.post_resource!(path, params)
    resp.body |> handle_response
  end

  defp handle_response(body) do
    case body do
      %{"message" => message, "errors" => errors} ->
        raise_error(message, errors)
      %{"number" => _, "title" => _ } -> body |> extract_id_title
      _ -> raise "Cannot handle #{body |> IO.inspect}"
    end
  end

  defp raise_error(message, errors) do
    error_str = errors |> Enum.map(&format_error(&1)) |> Enum.join("\n")
    raise "#{message}: #{error_str}"
  end

  defp format_error(error) do
    case error["code"] do
      "missing" ->
        res = error["resource"]
        "#{res} is missing."
      "missing_field" ->
        field = error["field"]
        "#{field} is missing."
      "invalid" ->
        field = error["field"]
        "#{field} is invalid."
      _ -> ""
    end
  end

  defp issues_path(remote) do
    "/repos/#{remote.repo}/issues"
  end

  defp pulls_path(remote) do
    "/repos/#{remote.repo}/pulls"
  end

  defp issue_path(remote, id) do
    "/repos/#{remote.repo}/issues/#{id}"
  end

  defp extract_id_title(pr) do
    %{id: pr["number"], title: pr["title"]}
  end

  defp category_url(remote, category, id) do
    # FIXME GitHub Enterprise
    host = "https://github.com"
    "#{host}/#{remote.repo}/#{category}/#{id}"
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
