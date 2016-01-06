defmodule BbCli do
  def main(args) do
    args |> process
  end

  def process(args) do
    subcommand = Enum.at(args, 0)
    other_args = Enum.drop(args, 1)

    {options, _, _} = OptionParser.parse(other_args,
      switches: [username: :string],
    )

    case subcommand do
      "repos" ->
        owner = options[:username]
         BitBucket.repositories(owner)
          |> print_results
      "reponame" ->
        extract_remote_urls
          |> extract_repo_names
          |> print_results
      _ ->
        IO.puts "Invalid argument"
    end
  end

  defp print_results(list) do
    IO.puts Enum.join(list, "\r\n")
  end

  defp extract_remote_urls do
    read_git_config
      |> Enum.filter(fn({k, v}) -> bitbucket_remote?(k, v) end)
      |> Enum.map(fn({k, v}) -> v[:url] end)
  end

  defp extract_repo_names(urls) do
    urls
      |> Enum.map(&Regex.replace(~r/^git@bitbucket.org:(.*).git$/, &1, "\\g{1}"))
  end

  defp bitbucket_remote?(section, value) do
    String.starts_with?(Atom.to_string(section), "remote") &&
      String.contains?(value[:url], "bitbucket.org")
  end

  defp read_git_config do
    {:ok, gitconfig_file} = File.read(".git/config")
    Ini.decode(gitconfig_file)
  end
end
