defmodule Git do
  @moduledoc """
  Module holding git (local) related methods.
  """

  def remote_urls do
    read_git_config
    |> Enum.filter(fn({k, _}) -> is_remote_section?(k) end)
    |> Enum.map(fn({_, v}) -> v[:url] end)
  end

  defp is_remote_section?(section) do
    String.starts_with?(Atom.to_string(section), "remote")
  end

  def git_dir(cur_path \\ ".") do
    expanded_cur_path = cur_path |> Path.expand
    cur_git_dir = expanded_cur_path |> Path.join(".git")

    if File.exists?(cur_git_dir) do
      cur_git_dir
    else
      if cur_path == "/" do
        nil
      else
        parent_dir = expanded_cur_path |> Path.join("..")
        git_dir(parent_dir)
      end
    end
  end

  def current_branch do
    {:ok, head_file} = File.read(Path.join(git_dir, "HEAD"))
    head_file
    |> String.replace(~r/^ref: refs\/heads\//, "", global: false)
    |> String.rstrip
  end

  def extract_repo_names(urls) do
    urls
    |> Enum.map(&Regex.replace(~r/^.*[\/:]([^\/:]+)\/([^\/]+).git/, &1, "\\g{1}/\\g{2}"))
  end

  defp read_git_config do
    {:ok, gitconfig_file} = File.read(Path.join(git_dir, "config"))
    Ini.decode(gitconfig_file)
  end
end
