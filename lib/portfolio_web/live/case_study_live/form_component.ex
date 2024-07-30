defmodule PortfolioWeb.CaseStudyLive.FormComponent do
  use PortfolioWeb, :live_component
  alias Portfolio.Content.Types
  alias Portfolio.Content

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="case_study-form"
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
          <.button phx-disable-with="Saving...">Save Case study</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{case_study: case_study} = assigns, socket) do
    changeset = Content.change("case_study", case_study)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"case_study" => case_study_params}, socket) do
    changeset =
      socket.assigns.case_study
      |> Content.change("case_study", case_study_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"case_study" => case_study_params}, socket) do
    save_case_study(socket, socket.assigns.action, case_study_params)
  end

  defp save_case_study(socket, :edit, case_study_params) do
    case Content.update(
           "case_study",
           socket.assigns.case_study,
           case_study_params
         ) do
      {:ok, case_study} ->
        notify_parent({:saved, case_study})

        {:noreply,
         socket
         |> put_flash(:info, "Case study updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @dialyzer {:nowarn_function, handle_event: 3}
  defp save_case_study(socket, :new, case_study_params) do
    case Content.create("case_study", case_study_params) do
      {:ok, case_study} ->
        notify_parent({:saved, case_study})

        {:noreply,
         socket
         |> put_flash(:info, "Case study created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
