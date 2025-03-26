ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Portfolio.Repo, :manual)

# Register essential components
Portfolio.TestComponents.ensure_essential_components_registered()
