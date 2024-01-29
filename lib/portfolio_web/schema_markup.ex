defmodule PortfolioWeb.SchemaMarkup do
  @moduledoc """
  Module for generating schema markup data.
  """

  @spec generate_person_schema() :: map
  def generate_person_schema do
    %{
      "@context" => "http://schema.org",
      "@type" => "Person",
      name: "Zane Riley",
      jobTitle: "Product Designer",
      description: "Experienced product designer based in Tokyo, Japan",
      url: "https://www.zaneriley.com/",
      image: "https://www.zaneriley.com/zane-riley.jpg",
      sameAs: [
        "https://www.linkedin.com/in/zaneriley",
        "https://github.com/zaneriley",
        "https://twitter.com/zaneriley",
      ],
      address: %{
        "@type" => "PostalAddress",
        addressLocality: "Tokyo",
        addressRegion: "Tokyo",
        addressCountry: "Japan"
      }
    }
  end
end
