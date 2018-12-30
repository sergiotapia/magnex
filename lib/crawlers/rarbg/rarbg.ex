defmodule Magnex.Crawlers.Rarbg do
  import Logger

  @api_url "https://torrentapi.org/pubapi_v2.php"

  def latest do
    valid_token = token()
    url = "#{@api_url}?token=#{valid_token}&mode=list&limit=100&format=json_extended&ranked=0"
    perform_request(url) |> IO.inspect()
    :timer.sleep(1)
  end

  def search(term) do
    valid_token = token()
    encoded_term = URI.encode(term)

    url =
      "#{@api_url}?token=#{valid_token}&mode=search&limit=100&format=json_extended&ranked=0&search_string=#{
        encoded_term
      }"

    perform_request(url) |> IO.inspect()
    :timer.sleep(1)
  end

  @spec token() :: {:ok, String.t()} | {:error, String.t()}
  def token do
    url = "#{@api_url}?get_token=get_token"
    {:ok, data} = perform_request(url)
    :timer.sleep(1)
    data["token"]
  end

  @spec perform_request(String.t()) :: {:ok, map()} | {:error, String.t()}
  def perform_request(url) do
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

        {:ok, {{_http, 200, 'OK'}, _headers, body}} = :httpc.request(:get, {url, headers}, [], [])
        JSON.decode(body)
    end
  end
end
