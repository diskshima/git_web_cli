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
