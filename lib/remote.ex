defprotocol Remote do
  def issues(remote, state)
  def issue_url(remote, id)
  def create_issue(remote, title, options)
  def close_issue(remote, id)
  def pull_requests(remote, state)
  def pull_request_url(remote, id)
  def create_pull_request(remote, title, source, dest)
end

defimpl Remote, for: BitBucket do
  @web_base_url "https://bitbucket.org"

  def issues(remote, state \\ nil) do
    all_issues = BitBucket.get_resource!("/repositories/" <> remote.repo <> "/issues")

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

  def close_issue(remote, id) do
    raise "Updating issues is not supported by the BitBucket API v2"
  end

  def pull_requests(remote, state \\ nil) do
    base_path = "/repositories/" <> remote.repo <> "/pullrequests"

    path = if state do
        base_path <> "?" <> URI.encode_query(%{state: String.upcase(state)})
      else
        base_path
      end

    resource = BitBucket.get_resource!(path)

    resource |> Enum.map(&to_simple_pr(&1))
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

defimpl Remote, for: GitLab do
  def issues(remote, state \\ nil) do
    project_id = remote |> GitLab.project_id

    base_path = "/projects/#{project_id}/issues"

    path = if state do
        base_path <> "?" <> URI.encode_query(%{state: state})
      else
        base_path
      end

    GitLab.get_resource!(path)
    |> Enum.map(&to_simple_pr(&1))
  end

  def create_issue(remote, title, options) do
    project_id = remote |> GitLab.project_id
    params = %{title: title}

    if options |> Dict.has_key?(:description) do
      params = params |> Dict.merge(%{description: options[:description]})
    end

    if options |> Dict.has_key?(:labels) do
      params = params |> Dict.merge(%{labels: options[:labels]})
    end

    resp = GitLab.post_resource!("/projects/#{project_id}/issues", params)

    resp.body |> to_simple_pr
  end

  def close_issue(remote, iid) do
    project_id = remote |> GitLab.project_id

    issue = remote |> get_issue(iid, [project_id: project_id])
    id = issue["id"]
    path = "/projects/#{project_id}/issues/#{id}"
    params = %{state_event: "close"}

    resp = GitLab.put_resource!(path, params)

    resp.body
    |> handle_response
  end

  def pull_requests(remote, state \\ nil) do
    project_id = remote |> GitLab.project_id
    base_path = "/projects/#{project_id}/merge_requests"

    path = if state do
        base_path <> "?" <> URI.encode_query(%{state: state})
      else
        base_path
      end

    resource = GitLab.get_resource!(path)

    resource |> Enum.map(&to_simple_pr(&1))
  end

  def create_pull_request(remote, title, source, dest) do
    project_id = remote |> GitLab.project_id
    params = %{title: title, source_branch: source}
    dest = dest || "master"
    params = params |> Dict.merge(target_branch: dest)

    resp = GitLab.post_resource!("/projects/#{project_id}/merge_requests",
      params)

    resp.body |> handle_response
  end

  defp get_issue(remote, iid, opts \\ []) do
    project_id = opts[:project_id]

    unless project_id, do: project_id = remote |> GitLab.project_id

    path = "/projects/#{project_id}/issues"
    params = [iid: iid]

    resource = GitLab.get_resource!(path, params)

    case resource do
      [] -> nil
      [issue] -> issue
      _ -> raise "More than one returned"
    end
  end

  defp handle_response(body) do
    case body do
      %{"message" => message} -> %{error: message}
      %{"iid" => _, "title" => _ } -> body |> to_simple_pr
      _ -> raise "Cannot handle #{body |> IO.inspect}"
    end
  end

  defp to_simple_pr(pr) do
    %{id: pr["iid"], title: pr["title"]}
  end

  def issue_url(remote, id) do
    category_url(remote, "issues", id)
  end

  def pull_request_url(remote, id) do
    category_url(remote, "merge_requests", id)
  end

  defp category_url(remote, category, id) do
    host = GitLab.OAuth2.host_name
    "#{host}/#{remote.repo}/#{category}/#{id}"
  end
end
