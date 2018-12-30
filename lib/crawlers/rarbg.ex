defmodule Magnex.Crawlers.Rarbg do
  require Logger

  @api_url "https://torrentapi.org/pubapi_v2.php"

  @doc """
  Fetches the latest torrents added the rarbg api.

  ## Examples

      iex> Magnex.Crawlers.Rarbg.latest
      {:ok, [%Torrent{}...]}

  """
  @spec latest() :: {:ok, list(Torrent.t())}
  def latest do
    valid_token = token()
    url = "#{@api_url}?token=#{valid_token}&mode=list&limit=100&format=json_extended&ranked=0"

    {:ok, data} = perform_request(url)

    torrents =
      Enum.map(data["torrent_results"], fn tdata ->
        %Torrent{
          title: tdata["title"],
          magnet_url: tdata["download"],
          seeders: tdata["seeders"],
          leechers: tdata["leechers"],
          created: tdata["pubdate"],
          size: tdata["size"]
        }
      end)

    {:ok, torrents}
  end

  @doc """
  Performs a search given a term.

  ## Examples

      iex> Magnex.Crawlers.Rarbg.search("big buck bunny")
      {:ok, [%Torrent{}...]}

  """
  @spec search(String.t()) :: {:ok, list(Torrent.t())}
  def search(term) do
    valid_token = token()
    encoded_term = URI.encode(term)

    url =
      "#{@api_url}?token=#{valid_token}&mode=search&limit=100&format=json_extended&ranked=0&search_string=#{
        encoded_term
      }"

    {:ok, data} = perform_request(url)

    torrents =
      Enum.map(data["torrent_results"], fn tdata ->
        %Torrent{
          title: tdata["title"],
          magnet_url: tdata["download"],
          seeders: tdata["seeders"],
          leechers: tdata["leechers"],
          created: tdata["pubdate"],
          size: tdata["size"]
        }
      end)

    {:ok, torrents}
  end

  defp token do
    url = "#{@api_url}?get_token=get_token"
    {:ok, data} = perform_request(url)
    data["token"]
  end

  defp perform_request(url) do
    case System.get_env("MAGNEX_APP_NAME") do
      nil ->
        error =
          "Environment variable for MAGNEX_APP_NAME must be set before calling any Magnex features."

        Logger.error(error)
        {:error, error}

      app_name ->
        url = (url <> "&app_id=#{app_name}") |> String.to_charlist()

        headers = [
          {'Content-Type', 'application/json'},
          {'User-Agent', 'magnex'}
        ]

        Process.sleep(2300)

        Logger.info("[rarbg] Web request: #{url}")
        {:ok, {{_http, 200, 'OK'}, _headers, body}} = :httpc.request(:get, {url, headers}, [], [])

        JSON.decode(body)
    end
  end
end
