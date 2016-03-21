defmodule Launchy do
  @moduledoc """
  The Launchy module will launch the given URL in the browser.
  """

  def open_url(url) do
    cond do
      osx? -> open_on_osx(url)
      linux? -> open_on_linux(url)
      windows? -> open_on_windows(url)
    end
  end

  defp open_on_osx(url) do
    System.cmd("open", [url])
  end

  defp open_on_linux(url) do
    System.cmd("xdg-open", [url])
  end

  defp open_on_windows(url) do
    System.cmd("start", ["launchy", "/b", url])
  end

  defp osx? do
    compare_os_type(:darwin)
  end

  defp linux? do
    compare_os_type(:linux)
  end

  defp windows? do
    compare_os_type(:nt)
  end

  defp compare_os_type(type) do
    :os.type |> elem(1) == type
  end
end
