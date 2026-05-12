# Content Authoring Contract

This repo consumes Markdown from `personal-site-content`. The content repo provides explicit fields; this app stores those fields and later maps them to rendered metadata or generated assets. There is no implicit natural-language interpretation in the current app.

## Share Preview Frontmatter

Use optional `share_*` fields to control how a content page should appear when someone shares it. These fields are author-facing vocabulary, not protocol vocabulary.

- `share_title`: short title for link preview cards. Falls back to `title`.
- `share_description`: description for link preview cards. Falls back to `introduction`.
- `share_image_direction`: stored editorial direction for a future share-image workflow. The current app does not turn this text into an image, URL, or tag. It is not a URL and should not contain generator-specific prompt syntax.
- `share_image_alt`: alt text for the generated or curated share image.

The app owns the explicit mapping from these fields into runtime output:

- Ingestion persists the fields on notes and case studies.
- A future share-image workflow can use `share_image_direction` as human/editorial input, then emit an image asset.
- The future metadata renderer maps the final title, description, image URL, and image alt into Open Graph and Twitter tags.
- Production smoke checks should validate the rendered metadata and image URL once generation exists.

Do not author `og_*`, `twitter_*`, or `og:image` fields in content files. Those names belong to rendered HTML metadata, not to the content authoring contract.

## Rename / Alias Frontmatter

Use optional `aliases` frontmatter when a published note or case study has been renamed and the old URL should keep working.

Example:

```yaml
url: "new-note-slug"
aliases:
  - "old-note-slug"
```

The aliases are content-type local. A note alias redirects from `/en/note/old-note-slug` to `/en/note/new-note-slug`; a case-study alias redirects within `/en/case-study/...`.

Alias rules:

- An alias must be an old slug, not a full URL or route path.
- An alias must use lowercase letters, numbers, and hyphens.
- An alias must not be blank.
- An alias must not duplicate the canonical `url`.
- Two live entries of the same content type must not claim the same alias.
- An alias must not conflict with another live canonical URL of the same content type.

Alias conflicts reject the content publish with a file path and reason. A pure deletion without an alias keeps the current explicit hard-404 behavior when it is shipped as a deletion-only content change. If a commit mixes deleted Markdown with added or modified Markdown, the deleted live URL must be preserved by a canonical URL or an alias in the new generation; otherwise the webhook rejects the publish so a rename cannot silently become a broken link.

## Draft Safety

The content repo should be safe to make public without exposing unpublished personal drafts. Any Markdown file with `is_draft: true` must be encrypted before it leaves the machine.

Local hooks should block or warn before push when they find unencrypted draft Markdown. They are a convenience for the authoring flow, not the guarantee: content-repo CI must run the same draft-safety check and fail before a PR can merge or a push to content `main` can publish.
