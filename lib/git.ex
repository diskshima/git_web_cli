defmodule Git do
  @moduledoc """
  Module holding git (local) related methods.
  """

  def remote_urls do
    read_git_config
    |> Enum.filter(fn({k, v}) -> is_remote_section?(k) end)
    |> Enum.map(fn({_, v}) -> v[:url] end)
  end

  defp is_remote_section?(section) do
    String.starts_with?(Atom.to_string(section), "remote")
  end

  def git_dir do
    # TODO Recursively search parent directories for any .git directory
    ".git"
  end

  def current_branch do
    {:ok, head_file} = File.read(Path.join(git_dir, "HEAD"))
    head_file
    |> String.replace(~r/^ref: refs\/heads\//, "", global: false)
    |> String.rstrip
  end

  defp read_git_config do
    {:ok, gitconfig_file} = File.read(Path.join(git_dir, "config"))
    Ini.decode(gitconfig_file)
  end
end
