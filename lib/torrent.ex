defmodule Torrent do
  @enforce_keys [:title, :magnet_url]
  defstruct [:title, :size, :seeders, :leechers, :created, :canonical_url, :magnet_url]
end
