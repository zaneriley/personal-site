defmodule Portfolio do
  @moduledoc """
  Defines the core domain logic and data management contexts for my personal website.

  Portfolio (the website's backend) organizes the primary business logic, separating
  it from the web interface (`PortfolioWeb`). This separation helps keep the
  website's core functionality, such as content management and data handling,
  independent from the presentation layer handled by Phoenix.

  Contexts within Portfolio group related functionalities and manage data access,
  whether it comes from the database, file system, or potentially external APIs
  in the future.

  ## Primary Contexts

  Currently, the main context provided by Portfolio is:

  *   `Portfolio.Content`: Manages all aspects of content entries (Notes, Case Studies),
      including their creation, retrieval from files or database, compilation
      (Markdown processing, AST generation), and translation handling.

  As the website evolves, other contexts might be added here to encapsulate
  different domain areas. You interact with these contexts to perform business
  operations related to the website's data and core features.
  """
end
