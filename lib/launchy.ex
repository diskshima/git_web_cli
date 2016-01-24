defmodule Launchy do
  @moduledoc """
  The Launchy module will launch the given URL in the browser.
  """

  def open_url(url) do
    cond do
      osx? -> System.cmd("open", [url])
      linux? -> open_on_linux(url)
    end
  end

  defp open_on_linux(url) do
    {command, args} = linux_command
    System.cmd(command, args ++ [url])
  end

  defp linux_command do
    case System.get_env("XDG_CURRENT_DESKTOP") do
      "XFCE" -> {"exo-open", ["--launch", "WebBrowser"]}
    end
  end

  defp osx? do
    compare_os_type(:darwin)
  end

  defp linux? do
    compare_os_type(:linux)
  end

  defp compare_os_type(type) do
    :os.type |> elem(1) == type
  end
end
