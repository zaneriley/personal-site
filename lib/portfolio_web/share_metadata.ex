defmodule PortfolioWeb.ShareMetadata do
  @moduledoc """
  Builds the `:share_metadata` assign consumed by `root.html.heex`.

  The app speaks `share_metadata` (a flat map). The layout is the only place
  that translates these keys into protocol vocabulary (`og:*`, `twitter:*`).
  No protocol vocabulary leaks here. `:image` resolves to the static default
  OG image for now; per-content overrides are Slice B.5, generated per-page
  OG images are Slice B.6.
  """

  alias PortfolioWeb.SiteOrigin

  @supported_locales Application.compile_env(:portfolio, :supported_locales)
  @default_image_path "/images/og-default.png"

  @type t :: %{
          title: String.t(),
          description: String.t(),
          type: String.t(),
          image: String.t(),
          url: String.t(),
          locale: String.t(),
          alternate_locales: [String.t()]
        }

  @spec build(keyword()) :: t()
  def build(opts) do
    title = Keyword.fetch!(opts, :title)
    description = Keyword.fetch!(opts, :description)
    locale = Keyword.fetch!(opts, :locale)
    path = Keyword.fetch!(opts, :path)

    %{
      title: title,
      description: description,
      type: Keyword.get(opts, :type, "website"),
      image: SiteOrigin.absolute_url(@default_image_path),
      url: SiteOrigin.absolute_url(path),
      locale: locale,
      alternate_locales: @supported_locales -- [locale]
    }
  end
end
