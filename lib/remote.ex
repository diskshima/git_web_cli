defprotocol Remote do
  def issues(remote, state)
  def pull_requests(remote, state)
end

defimpl Remote, for: BitBucket do
  def issues(remote, state \\ nil) do
    all_issues = BitBucket.get_resource!("/repositories/" <> remote.repo <> "/issues")

    filtered_issues = if state == nil do
        all_issues
      else
        all_issues |> Enum.filter(fn(issue) -> issue["state"] == state end)
      end

    filtered_issues
    |> Enum.map(fn(issue) -> %{id: issue["id"], title: issue["title"]} end)
  end

  def pull_requests(remote, state \\ nil) do
    base_path = "/repositories/" <> remote.repo <> "/pullrequests"

    path = if state do
        base_path <> "?" <> URI.encode_query(%{state: String.upcase(state)})
      else
        base_path
      end

    resource = BitBucket.get_resource!(path)

    resource
    |> Enum.map(fn(pr) ->
           %{id: pr["id"], title: pr["title"], url: pr["links"]["url"]}
         end)
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
    |> Enum.map(fn(issue) -> %{id: issue["id"], title: issue["title"]} end)
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

    resource
    |> Enum.map(fn(pr) ->
           %{id: pr["iid"], title: pr["title"], url: pr["links"]["url"]}
         end)
  end
end
