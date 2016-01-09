defmodule Launchy do
  def open_url(url) do
    if osx? do
      System.cmd("open", [url])
    end
  end

  defp osx? do
    :os.type |> elem(1) == :darwin
  end
end
