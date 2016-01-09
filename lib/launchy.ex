defmodule Launchy do
  @moduledoc """
  The Launchy module will launch the given URL in the browser.
  """

  def open_url(url) do
    if osx? do
      System.cmd("open", [url])
    end
  end

  defp osx? do
    :os.type |> elem(1) == :darwin
  end
end
