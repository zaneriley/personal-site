# ADR 0002 — Keep LiveView for app-like page transitions

**Status:** proposed 2026-05-14; awaiting Z ratification before implementation.
**Supersedes:** none.
**Superseded by:** none.

This ADR records the navigation/motion architecture direction surfaced by the 2026-05-14 View Transitions literature pass. It does not authorize implementation during the current preview-origin slice.

## Context

This site uses Phoenix LiveView partly because public navigation should feel continuous and app-like: pages should not feel like disconnected document loads when moving between the homepage, case studies, and notes.

That goal now has to be balanced against the resource-frugality work. The first-time visitor model makes cold mobile performance the hard floor. LiveView has a JavaScript and WebSocket cost, and the current browser budget work surfaced enough shipped JS that "use LiveView because we already have it" is not a sufficient argument.

The literature run at `.tmp/2026-05-14-view-transitions-architecture/literature/` produced a narrower answer: keep LiveView as the candidate navigation substrate, but make it earn that role through same-document View Transitions, measured bytes, and cold-mobile checks.

## Decision

For now, keep LiveView as the public navigation substrate. Do not replace it with Astro, a controller-only rewrite, Swup, Barba, Highway, or another client-side page-transition layer solely to get fades or app-like navigation.

When the app-like motion slice is scoped, prototype **same-document View Transitions through LiveView 1.1.18+'s `onDocumentPatch` hook** inside a single `live_session`. Navigation should use LiveView's live navigation path where possible so the root layout and WebSocket persist across public-page transitions.

The implementation must be progressive enhancement:

1. If View Transitions are unavailable, public navigation still works without broken or blocking motion.
2. Motion is opt-in under `@media (prefers-reduced-motion: no-preference)`.
3. Transition duration starts in the 200-300 ms range with easing, then is adjusted by measurement and visual review.
4. `view-transition-name` is applied through a LiveView-compatible hook or equivalent colocated mechanism, not assumed to survive inline HEEx/morphdom patches.
5. Cross-document View Transitions are deferred until browser support and site routing make them useful.

The active deploy/performance slice must still remove or lazy-load nonessential shipped JavaScript first, especially Easter egg or debug-only payloads, and must verify gzip/compression before assigning blame to LiveView itself.

## Why This Direction

Same-document View Transitions became Baseline Newly Available on 2025-10-14, including Firefox 144 support. LiveView v1.1.18 added the `onDocumentPatch` callback on 2025-11-25 specifically to let user code wrap LiveView DOM patches in `document.startViewTransition`. The maintainer-authored reference pattern wraps only the DOM patch, not the server round-trip.

That shape fits the site's goal better than adding a separate page-transition framework:

- It keeps the app in the Phoenix/LiveView stack already used by the content pages.
- It avoids a second client router or page-transition manager.
- It matches the "appy" continuity goal without committing to SPA architecture.
- It lets the performance harness measure the actual tradeoff: shipped JS, WebSocket bytes, first-load timing, and warm page-to-page behavior.

## Consequences

Immediate work does not change:

- Finish the preview-origin/config and browser-smoke slice first.
- Calibrate browser budgets after gzip/compression and JS attribution are understood.
- Split nonessential JavaScript out of the first-load path before judging LiveView's cost.

Later Slice C should include a small motion spike:

1. Upgrade or confirm LiveView is at least 1.1.18.
2. Add the `onDocumentPatch` View Transitions wiring behind feature detection.
3. Apply one route-pair transition between public pages.
4. Capture before/after browser artifacts for cold first load and warm navigation.
5. Review screenshots/video plus metrics before widening the pattern.

If the measured result shows LiveView cannot meet the site's cold-mobile and page-to-page goals even after gzip and JS cleanup, open a new ADR comparing smaller alternatives. Do not make that pivot by opportunistic refactor.

## References

- View Transitions literature brief: `.tmp/2026-05-14-view-transitions-architecture/literature/brief.md`
- web.dev same-document View Transitions Baseline note: `https://web.dev/blog/same-document-view-transitions-are-now-baseline-newly-available`
- Phoenix LiveView changelog for `onDocumentPatch`: `https://hexdocs.pm/phoenix_live_view/changelog.html`
- Steffen Deusch `onDocumentPatch` reference gist: `https://gist.github.com/SteffenDE/cf7cdb91ba037b08cdc583763e4ffc69`
- web.dev `prefers-reduced-motion` guidance: `https://web.dev/articles/prefers-reduced-motion`
