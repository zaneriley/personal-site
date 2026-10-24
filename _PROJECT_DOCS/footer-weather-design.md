# Footer weather: a small sense of place

Status: written as a design proposal on 2026-09-13 and implemented locally the
same day (commit `4cf391b`, on the `feat/theme-weather-icons` branch, not yet
on `origin/main`). Accepted by Z: WeatherAPI Free, one shared Tokyo reading
every 15 minutes, and Z supplying missing artwork. The sections before
**Local implementation — 2026-09-13** are the original proposal; where they
disagree with that section or the code (for example, the heading is "Tokyo",
not "Now in Tokyo", and the first-view greeting is not built), the code wins.
Open work is tracked in `BACKLOG.md` under **Theme toggle, footer weather, and
weather icons**.

## Job in the portfolio

The weather gives the profile a present tense: someone lives and makes things
in Tokyo, and this little corner of the page reflects the world around them.
The authored faces and careful typography make the information recognizably
Z's. It should reward reaching the footer without requiring an interaction.

For a hiring manager, the intended contribution is a memorable detail and
evidence of care when encountered. Work and writing still carry the argument
for hiring Z. For a fellow designer, it offers a closer look at illustration,
type, color, motion and restraint working together. For a returning reader,
changing weather makes a familiar page feel inhabited. These are product
hypotheses; we have no evidence that a weather widget improves hiring outcomes.

The successful impression is “this feels considered and personal.” A visitor
need not notice every animation or understand the machinery to get that.
Tokyo identifies the city; this feature does not expose a home address or ask
for the visitor's location.

## Experience and information hierarchy

Keep the existing footer location, after the work and reading experience.
Within the weather block, the order is city, icon with temperature, then a
short condition label. Use “Now in Tokyo” for fresh data. Celsius stays the
initial unit, and condition text follows the page's English/Japanese locale.

Use the existing Cheee temperature treatment and authored 28×28 weather
artwork as the starting point. Choose final optical size, alignment and text
weight in rendered review; do not assume enlarging the icon creates polish.
Place a quiet source link nearby. Freshness detail must be readable on touch
screens and with assistive technology, never available only through hover.

The weather illustration is informational, not a button. It must not resemble
the adjacent sun/moon theme control in placement or affordance. A clear Tokyo
night shows the moon even when the visitor prefers light mode. Rain remains
rain at night. Keep the artwork's colors distinct from semantic text/surface
tokens; verify visibility against both footer themes rather than globally
tinting the illustration.

On mobile, weather occupies an ordinary row in the footer's agreed grid.
Reserve space for the icon, negative and two-digit temperatures, and wrapping
Japanese condition text. It must not push contact links out of reach, overflow
at 320 CSS pixels, or hide information at 200% text zoom. The wider mobile-grid
and color-system repairs remain separately owned backlog work.

## What success means

| Quality | Visitor promise | Acceptance evidence |
|---|---|---|
| Instant | Weather is readable as soon as this part of the page paints. | Initial HTML contains a cached reading or honest unavailable state. No provider request in the render path, no spinner or entrance fade withholding text. ADR 0006's existing throttled readability and byte ratchets still pass. |
| Stable | Updates do not disturb reading or footer navigation. | Zero layout shift attributable to weather in loading, fresh, stale and unavailable scenarios; fixed icon box and stable block geometry. Test long EN/JA labels and negative temperatures. |
| Live | An open page can receive a new reading without reloading. | One application refresh every 15 minutes; connected footer reflects a new snapshot within 5 seconds of publication in controlled tests. Reconnection reads the latest snapshot. No upstream polling per visitor. |
| Truthful | A failed refresh never masquerades as new weather. | Source time and fetch time are separate; stale and expired states are exercised with a controlled clock. No guessed temperature or sunny fallback. |
| Polished | The detail has character without competing with the page. | Review real SVGs, typography and motion on a phone in both themes. Z judges the composition; passing tests alone does not establish this. |
| Accessible | The same meaning survives reduced motion, missing artwork and assistive technology. | Condition text conveys the icon's meaning; decorative image has empty alt. Reduced motion removes all animation. Updates do not steal focus or repeatedly announce themselves. |
| Quiet | This feature does no continuous decorative work. | No idle animation loop, per-frame timer or recurring browser weather fetch. A performance trace shows motion stops when complete and while offscreen. |

The five-second delivery target describes our application after receiving data;
it does not promise five-second weather observations. “Live” means periodically
updated current conditions, not a streaming sensor or an uptime guarantee.
With JavaScript unavailable, the initial snapshot remains useful; its source
time stays visible because it cannot age itself on an open static document.

## Selected numeral optics

Z selected the degree/unit adjustments in
[`assets/weather-temperature-optics.json`](../assets/weather-temperature-optics.json)
through the Cheee optical tuner. That file preserves the exact returned values
and review context (`24°F`, 32 px, dark surface), applying to both C and F.
The degree moves right 0.01 em and up 0.065 em from the study baseline, with
radius scaled 1.4 and stroke scaled 1.475; the gap before the unit is −0.035 em.
All em values refer to numeral size. The unit gap follows the degree's 0.30 em
advance, rather than measuring the visible outline gap. Derived values are
rounded export values; the base adjustments are the calculation inputs.

This selects optical adjustments, not the study's entire composition or motion
implementation. Integrating the off-axis numeral composition remains open;
plain Cheee text alone does not implement it. Verify the selected settings
across one to three digits, negatives, both units and both footer themes.

Z's font direction is automatic site-wide Cheee subsetting through the existing
font pipeline, not a manually maintained list or an initial weather-only font.
Coverage must follow design, locales, dynamic values and content publication.
The extraction mechanism remains to be proved; collecting only visible text
from a few routes cannot establish complete coverage. Evaluate the resulting
shared font against whole-visit performance and cold arrival at the footer
before choosing a separate or embedded representation.

## Motion proposal

Render the final readable state first. The illustration may perform one brief
greeting on its first viewport entry per document: for example, a small cloud
settle or sun-ray turn, using existing separable artwork groups. Prototype one
condition before extending the vocabulary. Give this rare character moment a
450 ms maximum, no entrance delay and no fade from invisible. Its purpose is
to reveal the illustration's character, not to signal loading or freshness.

For an actual condition change while visible, use a coordinated transition
of at most 240 ms; keep the numeric/text update immediate. Animate transform
and opacity only in this first implementation. Do not add path-morph geometry,
blur, continuous rain, a blinking “live” dot or repeated greetings on every
data refresh. Reuse motion tokens where they exist; any new token has one
weather-specific owner until a wider motion system needs it.

Reduced motion yields the static endpoint immediately, including removal of
opacity effects. Offscreen or hidden-tab changes go directly to their final
state; do not replay a queue on return. No hover is required and a tap on the
illustration does not trigger a hidden interaction. Stop and clean up animation
on removal. The existing mobile theme-switcher animation defect is a separate
issue and is not evidence that its motion can be reused successfully here.

## Data and failure behavior

The following age thresholds are proposed product tolerances, not WeatherAPI
guarantees. Measure age from the provider's data timestamp, not the last fetch.

| State | Definition | Presentation |
|---|---|---|
| Fresh | Valid source time no more than 30 minutes old | “Now in Tokyo”, temperature, condition/icon, quiet source time and attribution |
| Stale | More than 30 minutes, no more than 2 hours old | “Tokyo”, “Last reported …” with explicit Tokyo time, last temperature/condition; no character animation |
| Unavailable | No valid reading, or older than 2 hours | Keep “Tokyo” and a quiet unavailable label; hide weather values and icon while retaining layout space |
| Unknown condition | Temperature/time valid, condition code unrecognized | Keep valid temperature; say condition unavailable, omit icon; do not discard valid measurements or invent a condition |

A newly fetched old report remains old. Reject malformed measurements and
timestamps implausibly ahead of the server clock; define a small clock-skew
tolerance in adapter tests. On fetch failure, preserve the last valid reading
without resetting its age. One bounded request per scheduled attempt with a
finite timeout is sufficient initially; no unbounded automatic retries.

The application updates freshness at the age boundaries as well as on new
readings, so an open connected page cannot remain “Now” indefinitely. A
disconnected client should retain an explicit source time and mark the display
as last reported; reconnect obtains current state. Freshness and display labels
must behave correctly across Tokyo midnight. Never log the API key or provider
request URL containing it.

## DDD Shape

- **Domain story:** Tokyo weather gives visitors a truthful glimpse of the
  conditions where Z lives.
- **Candidate names:** `Weather`, `Reading`, `Condition`, `WeatherAPI`,
  `WeatherLive`.
- **Bad:** `FooterStatusManager`, `LocalData`, `WeatherWidgetService`;
  these conflate machine telemetry, location, acquisition and presentation.
- **Good:** `Portfolio.Weather` owns current weather; the footer presents it.
- **Chosen vocabulary:** a **reading** is a reported temperature, condition,
  daylight flag, location, source and source time; **fetched_at** records our
  acquisition time. **Freshness** is derived from source time and the current
  clock. A **condition** describes weather, independently of artwork. **Daylight**
  describes Tokyo at the reading's timestep, independently of the site theme.
- **Boundaries:** the provider adapter translates WeatherAPI codes and payloads
  into readings. The weather owner refreshes and publishes the latest snapshot.
  Presentation owns locale, units formatting, labels, assets and motion. Machine
  temperature, deployment status and content caching remain separate concerns.
- **Tests should read like:** “a clear Tokyo night stays a moon in light mode”;
  “an old report does not become fresh after a successful fetch”; “snow showers
  never display thunder”; “a provider outage does not delay the page”.
- **Terms to add/change/retire:** retire the hardcoded `status.tokyo_temp` path
  when integrated. Keep `WeatherAPI` at the external boundary. Do not call API
  readings “my station observations”.

Proposed initial API: `Weather.current(now)` returns a snapshot with an
optional reading and derived freshness, without waiting on HTTP. A supervised
weather owner schedules refreshes and maintains one snapshot. An asynchronous
fetch must not block snapshot reads. Use the existing Req/Finch and PubSub
facilities; no database history or generic multi-provider framework is needed.
Keep small reading/condition types with this owner initially; split files only
when the actual implementation makes that clearer.

For a future station, preserve provenance at the measurement level if sources
are combined: a station temperature and API sky condition cannot honestly share
one source/time label. That is a future model extension, not a reason to build
source arbitration today. Station ingestion belongs in the household workload
repo; the public portfolio consumes only an intentionally published reading.

## IA Shape

- **Reader goal:** change which weather is reported, how it looks, or how it
  updates without searching unrelated footer/server code.
- **First file they should open:** this design, linked from the project README
  and weather backlog entry.
- **Canonical source of truth:** this document owns the proposed feature
  contract; code/tests own implemented behavior, `BACKLOG.md` owns open work,
  and `assets/weather-icons.md` owns asset provenance/export instructions.
- **Organizing axis:** application domain in `lib/portfolio/`; presentation in
  `lib/portfolio_web/`; authored assets and browser behavior under `assets/`.
  Existing peers include content/feeds in the application and footer,
  typography, theme switcher and image components in the web layer.
- **Files/folders added:** the minimal weather owner/adapter, weather
  presentation and its LiveView integration, plus motion files if the visual
  prototype earns them. Tests mirror these owners.
- **Files/folders removed or collapsed:** remove the duplicate static Tokyo
  value from footer status. Keep server facts in their existing block.
- **Bad:** put provider requests into `Footer`, use `content_cache` simply
  because it exists, or create a parallel `widgets/` framework.
- **Good:** a weather boundary with one reusable presentation component and one
  place that turns external condition codes into domain conditions.

Proposed tree; these paths describe responsibilities, not scaffolding to create
ahead of implementation:

```text
lib/portfolio/weather.ex                    # snapshot, refresh lifecycle, freshness
lib/portfolio/weather/weather_api.ex        # external request + code translation
lib/portfolio_web/components/weather.ex     # reading -> accessible markup/assets
lib/portfolio_web/live/weather_live.ex      # connected updates and age boundaries
assets/css/_weather.css                     # layout and optional motion styles
assets/js/hooks/weather_hook.ts             # only if viewport motion is adopted
assets/static/images/weather/               # existing optimized artwork
test/portfolio/weather_test.exs
test/portfolio/weather/weather_api_test.exs
test/portfolio_web/components/weather_test.exs
test/portfolio_web/live/weather_live_test.exs
```

The existing footer is in the root layout, outside the page LiveView's regular
updates. Proposed integration is one embedded weather LiveView in that footer,
with a server-rendered first snapshot and subscriptions only after connection.
Verify this against the application's actual root-layout/session behavior
before committing to the mechanism: one subscription per connected instance,
no recursive layout, no duplicated footer, locale preserved on navigation,
and a static path for views that cannot host a connected weather instance.
Do not copy weather-fetch logic into every page LiveView.

## Artwork and completion sequence

Z owns fog/mist and freezing-precipitation artwork. Enumerate WeatherAPI's full
condition list before finalizing additional sleet/ice-pellet variants. Preserve
precise text where several codes share artwork. Snowflake and wind need agreed
roles; wind speed is a separate measurement, not an automatic condition override.

1. Build deterministic visual examples for fresh day/night, precipitation,
   long Japanese text, stale and unavailable states; review on the phone.
2. Implement the shared snapshot and explicit provider translation, proving
   that cold start and failures cannot block rendering.
3. Integrate connected refresh and freshness transitions; test document load,
   LiveView navigation, background/foreground and reconnect.
4. Add the single greeting and condition transition; verify reduced motion,
   offscreen behavior and actual phone performance. Keep the static experience
   complete throughout.
5. Import remaining Z artwork, run the existing performance gates without
   weakening ratchets, and review the full footer in both themes and locales.

No public publication follows automatically from completing this feature.

## Evidence and limits

- [WeatherAPI pricing](https://www.weatherapi.com/pricing.aspx) permits
  commercial use on Free, lists 100,000 calls/month and reports current-data
  updates every 10–15 minutes. Its plan uptime figures are not our site SLA.
- [WeatherAPI documentation](https://www.weatherapi.com/docs/) owns condition
  codes, source timestamps and daylight fields;
  [terms](https://www.weatherapi.com/terms.aspx) own permitted use.
- [Weather Text's firsthand stale-display failure](https://blog.persistent.info/2026/06/weather-text-work-location-mode.html)
  motivates detectable age; it does not establish our 30-minute/two-hour policy.
- [Homepage's weather implementation](https://github.com/gethomepage/homepage/blob/fcd9a715d9f6307a6e5ff41518bf5bf825b4864b/src/components/widgets/openmeteo/openmeteo.jsx)
  supplies prior art for cached acquisition and display; its framework is not
  a recommendation to change ours.
- [WAI decorative images](https://www.w3.org/WAI/tutorials/images/decorative/)
  and [informative images](https://www.w3.org/WAI/tutorials/images/informative/)
  explain why adjacent condition text determines icon alternative text.
- [ADR 0006](adrs/0006-time-first-performance-contract.md) remains the accepted
  performance contract. Motion timing, freshness thresholds and audience
  impressions in this design are proposals requiring verification, not
  externally established universal best practices.

## Local implementation — 2026-09-13

`Portfolio.Weather` owns the shared observation in ETS; reads never wait on
provider IO. A supervised task refreshes every 15 minutes with bounded HTTP
timeouts and no automatic retries. Source age becomes stale after 30 minutes
and unavailable after two hours. One shared timer publishes age boundaries;
subscribers reread the cache, including after reconnect or returning to a tab.
No per-visitor weather requests run.

`WeatherLive` is embedded in the root footer, with no page layout. The renderer
inlines one existing optimized SVG asset and uses the existing Cheee pipeline.
Weather artwork adds no separate image request. Temperature poses and the
selected optical JSON are resolved in server HTML using natural font advances;
no canvas measurements or font readiness promises gate the mark. The unit gap
and degree geometry use the parent numeral em. Initial rendering is static;
changed digits settle for 240 ms using transform/opacity only, with cancellation
on patches, disconnect, reduced motion, hidden tabs, offscreen exit and teardown.
The first-greeting animation in the proposal is deferred pending phone review.

The heading is “Tokyo” with a visible report time, rather than an unconditional
“Now” claim that could survive a disconnected socket. Missing art has truthful
localized text. Expired/missing data has an unavailable label, not a placeholder
number. An expandable source line gives the report date and WeatherAPI credit.

Set `WEATHER_API_KEY` in the private runtime environment to enable the source.
Tests never consume that key. A cold process restart initially has no reading;
this in-memory cache intentionally does not promise persistence across releases.
Font swapping remains the existing site behavior and needs whole-site measurement;
this implementation does not claim to eliminate it. No publication is implied.

Validation on the local working tree: 16 focused Elixir tests and 54 JS tests
passed (11 pre-existing JS skips); compilation, scoped formatting and lint
passed. The release-shaped browser gate passed both without a configured source
and with a scratch-only `-100°C` / snow observation injected into the release's
shared cache. The populated case measured 682–869 ms readable content and zero
CLS across all seven contracted routes, under the existing network/CPU throttle.
Its root HTML was 14,792 bytes against the unchanged 15,000-byte ratchet. The
existing seal's SVG paths were compacted with SVGO (three-decimal precision)
to recover the required headroom; no font pipeline change was made. Raw proof:
`.tmp/2026-09-13-weather-build/performance-populated.json`.

A real WeatherAPI observation, physical-phone motion review and slow-font
appearance review remain outstanding. The isolated motion hook is 712 bytes
gzipped; this is a component measurement, not the entire site JavaScript size.

Weather composition sizing uses the existing type and spacing scales:
`--latin-fs-4xl` for the icon square (45.6192–62.834px),
`--latin-fs-2xl` for the temperature (31.68–37.18px), `--space-1xs`
for their gap, and `--space-md` below the city label. These are existing
fluid type rungs, not a fixed icon-to-numeral ratio. Both locales keep the
Latin sizing for this numeral artwork. The exported 28×28 SVG fills its slot.

This is a mapping to the codebase's scale. Figma's observed 42px frame and
outlined numeral bounds do not establish a token binding or font size; the
original binding remains unverified because the Figma MCP quota was exhausted.
The earlier 1.3125em ratio was an unsupported inference and is removed.
Z selected 4xl artwork and vertical centering. The icon and temperature use
`align-items: center`; the provisional 0.35em vertical offset is removed. Desktop columns 9–12 accommodate long values.
