defprotocol Remote do
  def issues(remote, state)
  def issue_url(remote, id)
  def create_issue(remote, title, options)
  def close_issue(remote, id)
  def assign_issue(remote, id, assignee)
  def pull_requests(remote, state)
  def pull_request_url(remote, id)
  def create_pull_request(remote, title, source, dest, options)
  def assign_pull_request(remote, id, assignee)
  def save_oauth2_client_info(remote, client_id, client_secret)
end
