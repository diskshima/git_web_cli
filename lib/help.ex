defmodule Help do
  def all do
    """
    usage: gw <command> [<args>]

    commands:
      pull-requests (or prs)  - List pull requests
      pull-request (or pr)    - Create a pull request
      issues (or is)          - List issues
      issue (or i)            - Create an issue
      open (or o)             - Open issue/pull request in browser
      close (or cl)           - Close an issue
      set (or s)              - Set configurations
      help (or h)             - Display help
    """
  end

  def pull_requests do
    """
    usage: gw pull-requests [--state STATE]

    Lists the pull requests on the remote service.
    The value of STATE will differ depending on the service you are using.
    """
  end

  def prs do
    pull_requests
  end

  def pull_request do
    """
    usage: gw pull-request [--title TITLE] [--source SOURCE_BRANCH] [--target TARGET_BRANCH] [--r]

    Opens a pull request from SOURCE_BRANCH to TARGET_BRANCH.
    SOURCE_BRANCH will default to the current checked out branch and TARGET_BRANCH will default to master.
    '--r' will mark the remote branch to be deleted when the pull request is merged. It is only supported on BitBucket and will be ignored for other services.
    """
  end

  def pr do
    pull_request
  end

  def lookup(nil) do
    lookup("all")
  end

  def lookup(subcommand) do
    method = subcommand |> String.replace("-", "_")
    apply(Help, method |> String.to_atom, [])
  end
end
