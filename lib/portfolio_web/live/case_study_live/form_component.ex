defmodule PortfolioWeb.CaseStudyLive.FormComponent do
  use PortfolioWeb, :live_component

  alias Portfolio.Admin

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
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:url]} type="text" label="Slug" />
        <.input field={@form[:role]} type="text" label="Role" />
        <.input field={@form[:timeline]} type="text" label="Project timeline" />
        <.input field={@form[:read_time]} type="number" label="Estimated Read Time (in minutes)" />
        <.input
          field={@form[:platforms]}
          type="select"
          multiple
          label="Platforms"
          options={[{"Option 1", "option1"}, {"Option 2", "option2"}]}
        />
        <.input field={@form[:introduction]} type="text" label="Introduction" />
        <.input field={@form[:content]} type="text" label="Content" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Case study</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{case_study: case_study} = assigns, socket) do
    changeset = Admin.change_case_study(case_study)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"case_study" => case_study_params}, socket) do
    changeset =
      socket.assigns.case_study
      |> Admin.change_case_study(case_study_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"case_study" => case_study_params}, socket) do
    save_case_study(socket, socket.assigns.action, case_study_params)
  end

  defp save_case_study(socket, :edit, case_study_params) do
    case Admin.update_case_study(socket.assigns.case_study, case_study_params) do
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

  defp save_case_study(socket, :new, case_study_params) do
    case Admin.create_case_study(case_study_params) do
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
