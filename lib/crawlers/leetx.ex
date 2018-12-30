defmodule Magnex.Crawlers.Leetx do
  require Logger

  @site_url "https://1337x.to"
  @categories [
    "Anime",
    "Apps",
    "Documentaries",
    "Games",
    "Movies",
    "Music",
    "Other",
    "TV",
    "XXX"
  ]

  @doc """
  Fetches the latest torrents added to 1337x.

  ## Examples

      iex> Magnex.Crawlers.Leetx.latest
      {:ok, [%Torrent{}...]}

  """
  @spec latest() :: {:ok, list(Torrent.t())}
  def latest do
    # First we find all the links in each of the category's list table.
    leetx_links =
      for category <- @categories do
        for i <- [1, 2] do
          {:ok, html} = perform_request("#{@site_url}/cat/#{category}/#{i}/")

          html
          |> Floki.parse()
          |> Floki.find("a")
          |> Floki.attribute("href")
          |> Enum.filter(fn a -> String.contains?(a, "/torrent/") end)
        end
      end
      |> List.flatten()

    # From each link, we parse it's information individually.
    torrents =
      for link <- leetx_links do
        fetch_torrent_information(link)
      end

    {:ok, torrents}
  end

  @doc """
  Performs a search given a term.

  ## Examples

      iex> Magnex.Crawlers.Leetx.search("big buck bunny")
      {:ok, [%Torrent{}...]}

  """
  @spec search(String.t()) :: {:ok, list(Torrent.t())}
  def search(term) do
    # First we find all the links in each of the category's list table.
    term = String.replace(term, " ", "+")

    leetx_links =
      for i <- [1, 2] do
        {:ok, html} = perform_request("#{@site_url}/search/#{term}/#{i}/")

        html
        |> Floki.parse()
        |> Floki.find("a")
        |> Floki.attribute("href")
        |> Enum.filter(fn a -> String.contains?(a, "/torrent/") end)
      end
      |> List.flatten()

    # From each link, we parse it's information individually.
    torrents =
      for link <- leetx_links do
        fetch_torrent_information(link)
      end

    {:ok, torrents}
  end

  defp fetch_torrent_information(leetx_link) do
    {:ok, html_body} = perform_request("#{@site_url}#{leetx_link}")

    if html_body =~ "Bad Torrent ID" do
      Logger.error("[leetx] This torrent is 404'd, skipping.")
      nil
    else
      title =
        html_body
        |> Floki.find("title")
        |> Floki.text()
        |> String.replace("Download Torrent ", "")
        |> String.replace("| 1337x", "")
        |> String.replace("Download ", "")
        |> String.trim()

      title =
        if String.ends_with?(title, " Torrent") do
          String.replace(title, " Torrent", "")
        end

      magnet_url =
        html_body
        |> Floki.attribute("a", "href")
        |> Enum.filter(fn href -> String.starts_with?(href, "magnet") end)
        |> List.first()

      size =
        html_body
        |> Floki.find(".torrent-category-detail ul.list")
        |> Enum.at(0)
        |> Floki.find("li")
        |> Enum.at(3)
        |> Floki.find("span")
        |> Floki.text()
        |> String.split()

      size_value = Enum.at(size, 0)
      unit = Enum.at(size, 1)
      size = Sizes.to_bytes(size_value, unit)

      {leechers, _} =
        html_body
        |> Floki.find(".leeches")
        |> Enum.at(0)
        |> Floki.text()
        |> Integer.parse()

      {seeders, _} =
        html_body
        |> Floki.find(".seeds")
        |> Enum.at(0)
        |> Floki.text()
        |> Integer.parse()

      %Torrent{
        title: title,
        magnet_url: magnet_url,
        seeders: seeders,
        leechers: leechers,
        created: "",
        size: size,
        canonical_url: "#{@site_url}#{leetx_link}"
      }
    end
  end

  defp perform_request(url) do
    case System.get_env("MAGNEX_APP_NAME") do
      nil ->
        error =
          "Environment variable for MAGNEX_APP_NAME must be set before calling any Magnex features."

        Logger.error(error)
        {:error, error}

      app_name ->
        url = String.to_charlist(url)

        headers = [
          {'User-Agent', '#{app_name}'}
        ]

        Process.sleep(500)

        Logger.info("[leetx] Web request: #{url}")

        {:ok, {{_http, 200, 'OK'}, _headers, body}} = :httpc.request(:get, {url, headers}, [], [])
        {:ok, IO.iodata_to_binary(body)}
    end
  end
end
