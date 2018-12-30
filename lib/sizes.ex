defmodule Sizes do
  def to_bytes(size, unit) do
    size = sanitize(size)

    case unit do
      "KB" ->
        String.to_float(size) * 1_000

      "MB" ->
        String.to_float(size) * 1_000_000

      "GB" ->
        String.to_float(size) * 1_000_000_000

      _ ->
        raise("Tried to convert unsupported size: #{size} - unit: #{unit}")
    end
  end

  defp sanitize(size) do
    String.replace(size, ",", "")
  end
end
