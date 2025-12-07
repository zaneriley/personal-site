ExUnit.start()

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

# Register essential components
Portfolio.TestComponents.ensure_essential_components_registered()
