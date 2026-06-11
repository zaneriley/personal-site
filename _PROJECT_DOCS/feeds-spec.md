# Feeds — syndication spec

**Status:** ratified 2026-06-11 (one amendment at ratification: entry ids are locale-scoped — see Entry mapping). Grounded in the
2026-06-11 literature run (`.tmp/2026-06-11-rss-syndication/literature/brief.md`,
42 sources) — `[pNNN]` citations resolve there.

The site syndicates its writing through Atom feeds so committed readers
subscribe once and never miss a piece, without short notes flooding subscribers
who came for the long-form work. Feeds are the retention channel; discovery and
social distribution ride on top of them later (bridges, POSSE) and are out of
scope here.

## Feed taxonomy

Two-tier model — a curated default plus opt-in narrower/wider streams
[p300, p302, p303, p307]:

| Feed | Contents | Audience promise |
|---|---|---|
| **main** | every entry whose `main_feed` is true (defaults: all case studies, no notes) | "the substantial work, low volume" — the default subscription |
| **case-studies** | all published case studies | only the portfolio work |
| **notes** | all published notes | the full notes stream, volume and all |
| **everything** | union of all published entries | the explicit opt-in firehose [p300] |

### Main-feed membership: an editorial flag with type defaults

Membership in **main** is an editorial decision per entry, Molly White-style
promotion [p302], generalized to both content types:

- Frontmatter key: **`main_feed: true | false`** (authoring contract).
- Defaults when absent: **case studies `true`, notes `false`.**
- So: promoting a long-form note = `main_feed: true` on that note; demoting an
  off-topic case study = `main_feed: false`. The default path requires no
  authoring at all.

Schema: one boolean column per content type (nullable, null = type default at
query time — so changing a type default later doesn't require backfill).
This deliberately does NOT classify notes by kind or length — `word_count`
exists but length is a proxy; the real concept is "belongs in the curated
feed", and the flag names that decision directly. If a display-facing
note-kind taxonomy emerges later, it can *feed* this flag's default without
replacing it.

## URLs, locales, discovery

Content is bilingual; feeds mirror the page-route structure:

```
/:locale/feeds                      HTML — the /feeds discovery page
/:locale/feeds/main.xml             Atom
/:locale/feeds/case-studies.xml     Atom
/:locale/feeds/notes.xml            Atom
/:locale/feeds/everything.xml       Atom
/feed.xml                           301 → /en/feeds/main.xml (convention alias)
```

- **The `/feeds` page is part of the spec, not an extra** — a human-readable
  menu describing each feed's contents and expected volume so subscribers
  self-select before subscribing (the codified slash-page convention)
  [p306, p301, p302, p305].
- **Autodiscovery:** every page carries
  `<link rel="alternate" type="application/atom+xml">` for the locale's main
  feed; section index pages additionally advertise their section feed.
- Feed titles/descriptions are gettext-translated; each feed's `<feed>`
  carries `xml:lang` for its locale.

## Format and entry mapping

**Atom 1.0 only** for v1 (the better-specified format; Eleventy's default
[p205]). JSON Feed and RSS 2.0 are non-goals until a consumer demands them.

**Full content, not excerpts** — the unambiguous practitioner consensus
[p103, p104, p100]. The pipeline makes it nearly free: entries already carry
compiled HTML.

Entry mapping:

| Atom | Source |
|---|---|
| `<id>` | `tag:zaneriley.com,2026:<type>/<binary_id>/<locale>` — the DB id, NOT the slug URL. Slugs rename (the alias/301 machinery exists because they do); a URL-based id would duplicate every renamed entry in readers. The locale segment keeps the en and ja renderings of one translated entry distinct for readers subscribed to both locales' feeds. The tag URI never changes. |
| `<link rel="alternate">` | absolute canonical URL for the entry's locale |
| `<title>` | entry title |
| `<published>` / `<updated>` | `published_at` / `updated_at` (RFC 3339) |
| `<content type="html">` | the entry's compiled HTML, **with all relative URLs rewritten to absolute** — readers resolve nothing against the site |
| `<summary>` | `introduction` |
| `<author>` | site-level constant |

Only published, non-draft entries appear (`is_draft: false`, `published_at`
set). Feeds are ordered by `published_at` descending, capped at the most
recent 20 entries per feed.

## Consumer contract (acceptance criteria)

Derived from what the de-facto-standard consumer normalizes and what strict
readers punish [p209]. Each is a test:

1. Entry ids are stable across a slug rename (rename fixture → id unchanged).
2. All URLs in the feed — links AND inside content HTML — are absolute.
3. Dates are valid RFC 3339; `updated` never precedes `published`.
4. A note with `main_feed: true` appears in main; without it, it doesn't;
   a case study with `main_feed: false` disappears from main. Defaults hold
   when the key is absent.
5. Drafts and unpublished entries appear in no feed.
6. Content HTML survives sanitization: a case study containing a code block
   renders as readable (if unstyled) code in a reader — token spans degrade
   to plain text, never to broken markup.
7. en and ja feeds contain only their locale's entries.
8. Every page's HTML head carries main-feed autodiscovery; section pages also
   carry their section's.
9. `/feed.xml` 301s to `/en/feeds/main.xml`.
10. Responses carry `application/atom+xml`, an ETag or Last-Modified derived
    from the newest entry, and honor conditional requests with 304.

## Implementation shape

Consistent with the dormant-ecosystem finding [p200, p201, p202]: **hand-rolled
in Phoenix** — no feed library. The design to port is Tableau's named-feed
registry [p201]:

- A feed registry (compile-time data): name → `%{title, description, predicate}`
  where the predicate is a content query (type + main-feed membership), so
  adding a feed is a registry entry, not a controller.
- One `FeedController` action parameterized by feed name; unknown feed = 404.
- Atom rendered via an EEx XML template (the same shape the footer/site already
  uses for HTML); no XML builder dependency.
- Relative→absolute rewriting runs at feed render over the compiled HTML,
  using the canonical origin from endpoint config.

## Non-goals (v1), with the forward path noted

- **Native ActivityPub federation — never** in the Phoenix app; every
  in-window practitioner account reports beta-quality interop pain
  [p351, p357]. When fediverse/Bluesky reach is wanted, **bridge by
  delegation** (RSS Parrot consumes these feeds as-is; Bridgy Fed wants
  microformats2 + webmention later) [p206, p356]. Costs to accept knowingly:
  bridges are lossy and federated copies are irrevocable [p350].
- JSON Feed, RSS 2.0, WebSub push, email digests.
- Per-tag/per-topic feeds — the taxonomy is the four feeds above until a
  subscriber asks otherwise.
- Feed-level analytics.

## Open items

- /feeds page copy (volume descriptions per feed) — written at implementation.
- Whether the ja feeds launch alongside en or wait for translated-content
  coverage to justify them.
