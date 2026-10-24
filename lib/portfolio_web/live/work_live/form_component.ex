defmodule PortfolioWeb.WorkLive.FormComponent do
  use PortfolioWeb, :live_component
  alias Portfolio.Content

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="project-form"
        phx-target={@myself}
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:url]} type="text" label="Slug" />
        <.input field={@form[:role]} type="text" label="Role" />
        <.input field={@form[:timeline]} type="text" label="Project timeline" />
        <.input
          field={@form[:read_time]}
          type="number"
          label="Estimated Read Time (in minutes)"
        />
        <.input
          field={@form[:platforms]}
          type="select"
          multiple
          label="Platforms"
          options={[
            {"Mobile", "mobile"},
            {"Web", "web"},
            {"Desktop", "desktop"},
            {"Tablet", "tablet"},
            {"iOS", "iOS"},
            {"Android", "android"},
            {"Smart TV", "smart_tv"},
            {"Wearable", "wearable"},
            {"Voice Assistant", "voice_assistant"},
            {"Gaming Console", "gaming_console"},
            {"VR", "VR"},
            {"AR", "AR"},
            {"Smart Home Devices", "smart_home_devices"},
            {"Car Dashboard", "car_dashboard"},
            {"Google Maps", "google_maps"},
            {"Google Search", "google_search"},
            {"Blockchain", "blockchain"}
          ]}
        />
        <.input field={@form[:introduction]} type="text" label="Introduction" />
        <.input field={@form[:content]} type="textarea" label="Content" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Project</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{project: project} = assigns, socket) do
    changeset = Content.change("project", project)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      Content.change("project", socket.assigns.project, project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    save_project(socket, socket.assigns.action, project_params)
  end

  defp save_project(socket, :edit, project_params) do
    case Content.update(
           "project",
           socket.assigns.project,
           project_params
         ) do
      {:ok, project} ->
        notify_parent({:saved, project})

        {:noreply,
         socket
         |> put_flash(:info, "Project updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, reason} ->
        Logger.error("Failed to update project: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Project could not be updated")}
    end
  end

  defp save_project(socket, :new, project_params) do
    case Content.create("project", project_params) do
      {:ok, project} ->
        notify_parent({:saved, project})

        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, reason} ->
        Logger.error("Failed to create project: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Project could not be created")}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
