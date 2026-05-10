defmodule Portfolio.Content.Remote.GitHubStatusClient do
  @moduledoc """
  Boundary for writing content publication statuses back to GitHub.
  """

  @type status_payload :: %{
          required(:state) => String.t(),
          required(:context) => String.t(),
          optional(:description) => String.t(),
          optional(:target_url) => String.t()
        }

  @callback create_status(
              String.t(),
              String.t(),
              String.t(),
              status_payload(),
              keyword()
            ) :: :ok | {:error, term()}
end
