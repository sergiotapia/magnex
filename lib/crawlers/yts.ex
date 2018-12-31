defmodule Magnex.Crawlers.Yts do
  @moduledoc """
  Provides access to latest and search for Yts.am torrents.
  """

  require Logger

  @site_url "https://yts.am"

  @doc """
  Fetches the latest torrents added to yts.am.

  ## Examples

      iex> Magnex.Crawlers.Yts.latest
      {:ok, [%Torrent{}...]}

  """
  @spec latest() :: {:ok, list(Torrent.t())}
  def latest do
    yts_links =
      for i <- [1, 2] do
        {:ok, html} = perform_request("#{@site_url}/browse-movies?page=#{i}")

        html
        |> Floki.parse()
        |> Floki.find("a.browse-movie-link")
        |> Floki.attribute("href")
        |> Enum.filter(fn a -> String.contains?(a, "/movie/") end)
      end
      |> List.flatten()

    torrents =
      for link <- yts_links do
        fetch_torrent_information(link)
      end
      |> List.flatten()

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
    encoded_term = URI.encode(term)
    {:ok, html} = perform_request("#{@site_url}/browse-movies/#{encoded_term}/all/all/0/latest")

    yts_links =
      html
      |> Floki.parse()
      |> Floki.find("a.browse-movie-link")
      |> Floki.attribute("href")
      |> Enum.filter(fn a -> String.contains?(a, "/movie/") end)

    torrents =
      for link <- yts_links do
        fetch_torrent_information(link)
      end
      |> List.flatten()

    {:ok, torrents}
  end

  defp fetch_torrent_information(yts_link) do
    {:ok, html_body} = perform_request(yts_link)

    magnet_urls =
      html_body
      |> Floki.attribute("a", "href")
      |> Enum.filter(fn href -> String.starts_with?(href, "magnet") end)

    case length(magnet_urls) do
      2 ->
        parse_two_qualities(yts_link, html_body)

      1 ->
        parse_single_quality(yts_link, html_body)

      _ ->
        nil
    end
  end

  defp parse_single_quality(yts_link, html_body) do
    magnet_url =
      html_body
      |> Floki.attribute("a", "href")
      |> Enum.filter(fn href -> String.starts_with?(href, "magnet") end)
      |> List.first()

    title =
      html_body
      |> Floki.find("h1")
      |> List.first()
      |> Floki.text()
      |> String.trim()
      |> String.replace("Please enable your VPN when downloading torrents", "")

    quality_html_node =
      html_body
      |> Floki.find("p.quality-size")
      |> List.last()

    [size, unit] = Floki.text(quality_html_node) |> String.split(" ")
    size = Sizes.to_bytes(size, unit)

    %Torrent{
      title: title,
      magnet_url: magnet_url,
      seeders: 0,
      leechers: 0,
      created: "",
      size: size,
      canonical_url: yts_link
    }
  end

  defp parse_two_qualities(yts_link, html_body) do
    magnet_urls =
      html_body
      |> Floki.attribute("a", "href")
      |> Enum.filter(fn href -> String.starts_with?(href, "magnet") end)

    title =
      html_body
      |> Floki.find("h1")
      |> List.first()
      |> Floki.text()
      |> String.trim()
      |> String.replace("Please enable your VPN when downloading torrents", "")

    quality_html_nodes =
      html_body
      |> Floki.find("p.quality-size")

    sizes =
      [Enum.at(quality_html_nodes, 1), Enum.at(quality_html_nodes, 3)]
      |> Enum.map(fn quality ->
        [size, unit] = Floki.text(quality) |> String.split(" ")
        Sizes.to_bytes(size, unit)
      end)

    [
      %Torrent{
        title: title,
        magnet_url: List.first(magnet_urls),
        seeders: 0,
        leechers: 0,
        created: "",
        size: List.first(sizes),
        canonical_url: yts_link
      },
      %Torrent{
        title: title,
        magnet_url: List.last(magnet_urls),
        seeders: 0,
        leechers: 0,
        created: "",
        size: List.last(sizes),
        canonical_url: yts_link
      }
    ]
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

        Logger.info("[yts] Web request: #{url}")

        {:ok, {{_http, 200, 'OK'}, _headers, body}} = :httpc.request(:get, {url, headers}, [], [])
        {:ok, IO.iodata_to_binary(body)}
    end
  end
end
