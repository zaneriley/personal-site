ExUnit.start()

# Trust paths git operates on inside the container. Bind-mounted volumes
# (e.g. priv/content) are owned by the host UID, which trips git ≥ 2.35's
# safe.directory check. Belt-and-suspenders with the docker entrypoint.
# `env: []` keeps inherited env (incl. anything sensitive) out of the spawned
# git process — required, even though this command doesn't read env.
System.cmd("git", ~w(config --global --add safe.directory *),
  env: [],
  stderr_to_stdout: true
)

# Explicitly ensure the repo is configured for Sandbox *before* setting the mode.
# Workaround for initialization issues seen with render_component tests via ./run
Application.put_env(
  :portfolio,
  Portfolio.Repo,
  Keyword.merge(Application.get_env(:portfolio, Portfolio.Repo, []),
    pool: Ecto.Adapters.SQL.Sandbox
  )
)

Ecto.Adapters.SQL.Sandbox.mode(Portfolio.Repo, :manual)

Mox.defmock(
  Portfolio.Content.Remote.GitHubStatusClient.Mock,
  for: Portfolio.Content.Remote.GitHubStatusClient
)

Mox.defmock(
  Portfolio.Content.Remote.GitCommand.Mock,
  for: Portfolio.Content.Remote.GitCommand
)

# Register essential components
Portfolio.TestComponents.ensure_essential_components_registered()
