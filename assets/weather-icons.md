# Weather icons

Ten original Figma vectors live in `static/images/weather/`. The existing esbuild
static-copy plugin copies them to `priv/static/images/weather/`; Phoenix serves
them at `/images/weather/<name>.svg`.

Icons use square viewBoxes centered on their visible path bounds, with 0.1 source
units of clearance. This removes uneven export padding so the shared size token
sizes the artwork and centers it consistently. Original paths, face cutouts,
and the three authored color roles remain intact. Paths are optimized to two decimal places with the
shared SVGO configuration. IDs are prefixed per icon; repeated inline instances
still need instance-specific IDs if they use a clip path.

## Two separate sun/moon drawings

There are two unrelated sets of sun and moon geometry. Do not swap one for the
other.

- **Weather artwork** — `static/images/weather/sun.svg` and `moon.svg`, 28×28,
  exported from the Figma weather collection (nodes `4113:956` and `4113:965`).
  Only the footer weather uses them. Their face paths keep the
  `weather-sun-face` and `weather-moon-face` IDs in case the weather greeting
  animation is built later; nothing references those IDs today.
- **Theme toggle artwork** — `js/sun-moon-paths.json`, 24×24 contour pairs
  normalized for morphing between sun and moon. It comes from the
  [Sun & moon prototype](https://sun-moon-motion.zaneriley.chatgpt.site), not
  from the Figma weather node. The prototype's contours are rounded to four
  decimal places at import; animation frames are written with three.
  `js/sun-moon-motion.ts` owns the interruptible spring and the face
  choreography. The toggle follows the operating-system theme until the visitor
  explicitly picks one.

## Source mapping

[Figma weather collection](https://www.figma.com/design/zDOcBhnjTDCWmc6OFgeoUc/Zane-Riley-s-Product-Portfolio?node-id=4113-955).
File names here describe the visible artwork. Half of the layer names in Figma
are stale (for example, the sun is still called "snowflake"). The table below is
the only mapping between the two; renaming the Figma layers is open and is Z's
task in Figma. The theme toggle's morph paths are not in this collection.

| Asset | Figma node | Original layer name |
| --- | --- | --- |
| `sun.svg` | `4113:956` | snowflake |
| `partly-cloudy-day.svg` | `4113:958` | partly-sunny |
| `cloudy.svg` | `4113:963` | windy |
| `moon.svg` | `4113:965` | thermometer |
| `partly-cloudy-night.svg` | `4113:967` | partly-sunny-rain |
| `thunderstorm.svg` | `4113:974` | cloudy-windy |
| `rain.svg` | `4113:979` | rainy |
| `snowflake.svg` | `4113:985` | snow |
| `snow.svg` | `4113:987` | cloudy-snow |
| `wind.svg` | `4118:1337` | windy |

Conditions with no artwork yet (fog, mist, freezing precipitation, sleet, ice
pellets, haze, dust, smoke, smog) render as condition text with no icon. The
open artwork list lives in `_PROJECT_DOCS/BACKLOG.md`. `snowflake.svg` and
`wind.svg` exist but no condition maps to them yet.

Optimize just this collection from the repository root with the running JS container:

```sh
./run _dc js yarn svgo --config svgo.config.js -f static/images/weather -o static/images/weather
```

For a decorative image inside a labeled control, use empty alternative text.
For weather information, provide the condition as adjacent text or meaningful
alternative text. The weather footer inlines these assets so their fills inherit the theme:
clouds/wind use `--neutral-50`, precipitation uses `--accent`, and sun/moon
use `--illustration-warm`. Flat warm art retains its original dark pink rather
than the grain-compensated signature color; light uses the existing light art
palette. Literal fallbacks preserve standalone SVG previews, which cannot
inherit the embedding page's CSS tokens. White in the clip path is geometry,
not a visible illustration color.
