defprotocol Remote do
  def issues(repo, state)
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
end

defimpl Remote, for: GitLab do
  def issues(remote, state \\ nil) do
    project_id = GitLab.project_id
    all_issues = GitLab.get_resource!("/projects/#{project_id}/issues")
  end
end
