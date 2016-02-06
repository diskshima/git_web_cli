defimpl Remote, for: BitBucket do
  @web_base_url "https://bitbucket.org"

  def issues(remote, state \\ nil) do
    state = state || "new"

    resource = BitBucket.get_resource!("/repositories/#{remote.repo}/issues").body

    all_issues = resource["values"]

    filtered_issues = if state == nil do
        all_issues
      else
        all_issues |> Enum.filter(fn(issue) -> issue["state"] == state end)
      end

    filtered_issues
    |> Enum.map(&to_simple_pr(&1))
  end

  def create_issue(remote, title, options) do
    params = %{title: title}

    if options |> Dict.has_key?(:description) do
      params = params |> Dict.merge(%{content: %{raw: options[:description]}})
    end

    if options |> Dict.has_key?(:kind) do
      params = params |> Dict.merge(%{kind: options[:kind]})
    end

    if options |> Dict.has_key?(:priority) do
      params = params |> Dict.merge(%{priority: options[:priority]})
    end

    resp = BitBucket.post_resource!("/repositories/#{remote.repo}/issues",
      params)

    handle_response(resp.body)
  end

  def close_issue(_, _) do
    raise "Updating issues is not supported by the BitBucket API v2"
  end

  def pull_requests(remote, state \\ nil) do
    base_path = "/repositories/#{remote.repo}/pullrequests"

    path = if state do
        query_string = URI.encode_query(%{state: String.upcase(state)})
        "#{base_path}?#{query_string}"
      else
        base_path
      end

    resource = BitBucket.get_resource!(path)

    resource.body["values"] |> Enum.map(&to_simple_pr(&1))
  end

  def create_pull_request(remote, title, source, dest \\ nil) do
    params = %{title: title, source: %{branch: %{name: source}}}

    if dest do
      params = params |> Dict.merge(destination: %{branch: %{name: dest}})
    end

    resp = BitBucket.post_resource!(
      "/repositories/#{remote.repo}/pullrequests", params)

    handle_response(resp.body)
  end

  def issue_url(remote, id) do
    category_url(remote.repo, "issues", id)
  end

  def pull_request_url(remote, id) do
    category_url(remote.repo, "pull-requests", id)
  end

  defp category_url(repo, category, id) do
    "#{@web_base_url}/#{repo}/#{category}/#{id}"
  end

  defp handle_response(body) do
    case body do
      %{"error" => %{"fields" => fields}} ->
        %{error: build_field_error(fields)}
      %{"error" => msg} -> %{error: msg}
      %{"id" => _, "title" => _ } -> body |> to_simple_pr
      _ -> raise "Cannot handle #{body |> IO.inspect}"
    end
  end

  defp build_field_error(fields) do
    fields
    |> Enum.map(fn({field, msg}) ->
      msgs = msg |> Enum.join(",")
      "#{field}: #{msgs}" end)
    |> Enum.join(",")
  end

  defp to_simple_pr(pr_body) do
    %{id: pr_body["id"], title: pr_body["title"]}
  end
end


