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

The sun and moon are shared weather/theme assets. Their face paths retain
`weather-sun-face` and `weather-moon-face` IDs for future animation work.
The theme control now uses the original 24×24 morph artwork from the
[Sun & moon prototype](https://sun-moon-motion.zaneriley.chatgpt.site), stored in
`js/sun-moon-paths.json`. These static 28×28 weather assets remain separate
from that normalized animation geometry. The prototype's original contour pairs
are rounded to four decimal places at import; frame output uses three.
`js/sun-moon-motion.ts` owns the interruptible spring and facial choreography.
The binary control follows the OS until the user explicitly selects a theme.

## Source mapping

[Figma weather collection](https://www.figma.com/design/zDOcBhnjTDCWmc6OFgeoUc/Zane-Riley-s-Product-Portfolio?node-id=4113-955).
File names describe the visible artwork; some original layer names are stale.

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
