defmodule Portfolio.LoggerFormatter do
  def format(level, message, timestamp, metadata) do
    [
      format_timestamp(timestamp),
      format_level(level),
      format_module(metadata),
      format_message(message),
      format_metadata_inline(metadata),
      "\n"
    ]
    |> IO.ANSI.format()
  end

  defp format_timestamp(
         {{_year, _month, _day}, {hour, minute, second, millisecond}}
       ) do
    formatted_time =
      :io_lib.format("~2..0B:~2..0B:~2..0B.~3..0B", [
        hour,
        minute,
        second,
        millisecond
      ])

    [:cyan, "#{formatted_time} "]
  end

  defp format_level(level) do
    color =
      case level do
        :debug -> :green
        :info -> :blue
        :warn -> :yellow
        :warning -> :yellow
        :error -> :red
        _ -> :normal
      end

    [color, "[#{String.upcase(to_string(level))}] "]
  end

  defp format_module(metadata) do
    case Keyword.get(metadata, :module) do
      nil -> ""
      module -> [:magenta, "[#{inspect(module)}]\n"]
    end
  end

  defp format_message(message) do
    [:bright, "  #{message}\n"]
  end

  defp format_metadata_inline(metadata) do
    function = format_function(metadata)
    line = Keyword.get(metadata, :line, "")
    request_id = Keyword.get(metadata, :request_id, "")

    [
      :faint,
      "  #{function}",
      (line != "" && ", Line #{line}") || "",
      (request_id != "" && ", Request: #{request_id}") || ""
    ]
  end

  defp format_function(metadata) do
    case Keyword.get(metadata, :function) do
      [name, "/", arity] -> "#{name}/#{arity}"
      other -> inspect(other)
    end
  end
end
