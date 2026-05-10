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

## Draft Safety

The content repo should be safe to make public without exposing unpublished personal drafts. Any Markdown file with `is_draft: true` must be encrypted before it leaves the machine.

Local hooks should block or warn before push when they find unencrypted draft Markdown. They are a convenience for the authoring flow, not the guarantee: content-repo CI must run the same draft-safety check and fail before a PR can merge or a push to content `main` can publish.
