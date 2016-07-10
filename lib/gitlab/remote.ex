defimpl Remote, for: GitLab do
  def issues(remote, state \\ nil) do
    state = state || "opened"

    project_id = remote |> GitLab.project_id

    base_path = "/projects/#{project_id}/issues"

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
    path = remote |> issue_path(iid)
    params = %{state_event: "close"}

    resp = GitLab.put_resource!(path, params)

    resp.body
    |> handle_response
  end

  def assign_issue(remote, iid, assignee) do
    path = remote |> issue_path(iid)

    # TODO Most likely will not work with the username.
    params = %{assignee_id: assignee}

    resp = GitLab.put_resource!(path, params)

    resp.body
    |> handle_response
  end

  def pull_requests(remote, state \\ nil) do
    state = state || "opened"

    project_id = remote |> GitLab.project_id
    base_path = "/projects/#{project_id}/merge_requests"

    path = if state do
        query_string = URI.encode_query(%{state: state})
        "#{base_path}?#{query_string}"
      else
        base_path
      end

    values = aggregate_results(path, [])

    values |> Enum.map(&to_simple_pr(&1))
  end

  def create_pull_request(remote, title, source, dest, options \\ nil) do
    if options |> Keyword.has_key?(:remove_source_branch) do
      IO.puts("Warining: remove source branch on pull request creation is not supported in GitLab. Ignoring the option.")
      options = options |> Keyword.delete(:remove_source_branch)
    end

    project_id = remote |> GitLab.project_id
    dest = dest || "master"
    params = %{title: title, source_branch: source, target_branch: dest}

    resp = GitLab.post_resource!("/projects/#{project_id}/merge_requests",
      params)

    resp.body |> handle_response
  end

  def assign_pull_request(remote, id, assignee) do
    path = remote |> merge_request_path(id)
    params = %{assignee_id: assignee}

    resp = GitLab.put_resource!(path, params)

    resp.body |> handle_response
  end

  def save_oauth2_client_info(remote, client_id, client_secret) do
    GitLab.OAuth2.save_client_info(client_id, client_secret)
  end

  defp get_issue(remote, iid, opts \\ []) do
    remote |> get_item("issues", iid)
  end

  defp get_pull_request(remote, iid, opts \\ []) do
    remote |> get_item("merge_requests", iid, opts)
  end

  defp get_item(remote, category, iid, opts \\ []) do
    project_id = opts[:project_id]

    unless project_id, do: project_id = remote |> GitLab.project_id

    path = "/projects/#{project_id}/#{category}"
    params = [iid: iid]

    resource = GitLab.get_resource!(path, params)

    case resource.body do
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

  defp aggregate_results(nil, values) do
    values
  end

  defp aggregate_results(url, values) do
    resource = GitLab.get_resource!(url)

    values = values ++ resource.body

    link_value = resource.headers |> Utils.find_header("Link")

    link_header = ExLinkHeader.parse!(link_value)

    aggregate_results(link_header["next"]["url"], values)
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

  defp issue_path(remote, iid) do
    project_id = remote |> GitLab.project_id
    issue = remote |> get_issue(iid)
    id = issue["id"]
    "/projects/#{project_id}/issues/#{id}"
  end

  defp merge_request_path(remote, iid) do
    project_id = remote |> GitLab.project_id
    pr = remote |> get_pull_request(iid)
    id = pr["id"]
    "/projects/#{project_id}/merge_requests/#{id}"
  end
end
