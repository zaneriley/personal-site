defmodule Portfolio.LoggerFormatter do
  @moduledoc """
  A custom logger formatter for the Portfolio application.

  This formatter is responsible for formatting log messages in a specific format that is consistent with the application's logging requirements.
  """

  @doc """
  Formats a log message.

  The formatter takes the following arguments:
    - level: The log level of the message (e.g., :debug, :info, :warn, :error)
    - message: The log message to be formatted
    - timestamp: The timestamp of the log message
    - metadata: Additional metadata associated with the log message

  The formatter returns a formatted log message as a string.
  """
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
