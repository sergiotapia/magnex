defmodule JSON do
  @json Application.get_env(:magnex, :json_library) ||
          raise("You must set your json library config for magnex.json_library")

  def decode(json) do
    @json.decode(json)
  end

  def encode_to_iodata(json) do
    @json.encode_to_iodata(json)
  end
end
