defmodule PortfolioWeb.ShareMetadataTest do
  use ExUnit.Case, async: true
  alias PortfolioWeb.ShareMetadata

  describe "build/1" do
    test "returns required fields verbatim" do
      meta =
        ShareMetadata.build(
          title: "Page title",
          description: "Page description",
          locale: "en",
          path: "/en/note/foo"
        )

      assert meta.title == "Page title"
      assert meta.description == "Page description"
      assert meta.locale == "en"
    end

    test "defaults :type to website" do
      meta =
        ShareMetadata.build(
          title: "Page title",
          description: "Page description",
          locale: "en",
          path: "/en"
        )

      assert meta.type == "website"
    end

    test "honors :type override" do
      meta =
        ShareMetadata.build(
          title: "Page title",
          description: "Page description",
          locale: "en",
          path: "/en/note/foo",
          type: "article"
        )

      assert meta.type == "article"
    end

    test ":url is the absolute URL for the given path" do
      meta =
        ShareMetadata.build(
          title: "Page title",
          description: "Page description",
          locale: "en",
          path: "/en/note/foo"
        )

      assert meta.url == PortfolioWeb.SiteOrigin.absolute_url("/en/note/foo")
    end

    test ":image is the absolute URL of the default OG image" do
      meta =
        ShareMetadata.build(
          title: "Page title",
          description: "Page description",
          locale: "en",
          path: "/en"
        )

      assert meta.image ==
               PortfolioWeb.SiteOrigin.absolute_url("/images/og-default.png")
    end

    test ":alternate_locales excludes the current locale" do
      meta =
        ShareMetadata.build(
          title: "Page title",
          description: "Page description",
          locale: "en",
          path: "/en"
        )

      assert meta.alternate_locales == ["ja"]

      meta_ja =
        ShareMetadata.build(
          title: "Page title",
          description: "Page description",
          locale: "ja",
          path: "/ja"
        )

      assert meta_ja.alternate_locales == ["en"]
    end

    test "raises when a required key is missing" do
      assert_raise KeyError, fn ->
        ShareMetadata.build(
          description: "Page description",
          locale: "en",
          path: "/en"
        )
      end

      assert_raise KeyError, fn ->
        ShareMetadata.build(
          title: "Page title",
          locale: "en",
          path: "/en"
        )
      end

      assert_raise KeyError, fn ->
        ShareMetadata.build(
          title: "Page title",
          description: "Page description",
          path: "/en"
        )
      end

      assert_raise KeyError, fn ->
        ShareMetadata.build(
          title: "Page title",
          description: "Page description",
          locale: "en"
        )
      end
    end
  end
end
