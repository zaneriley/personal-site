# Media treatment: photos and screens

Status: direction committed by Z on 2026-10-31. Prototyped in the browser
([`media-prototype/`](../media-prototype/)), not yet built into the app. The
numbers below are the current defaults. They are good enough to build on, and
the **Revisit later** list says where each one is still loose.

## The idea

The site mixes references on purpose so no single genre takes over. Arches,
serif type and a dark palette together read as medieval costume, so each piece
borrows from somewhere different.

The mood comes from botanica, the music genre: warm human material processed
by machines. It should feel like growing, not decaying, and personal rather
than sad. In practice:

- The machine always works on the image's own material. A border is grown from
  the photo's pixels, and a screen's background is made from the screenshot.
- Texture lives on the pixel grid. Patterns that look like processed fields
  work. Patterns that look like drawn marks (lines, dots, rings, threads,
  tiles) read as generic computer art.
- Color stays in the site's grade: darkened into the site's range and pulled
  toward its grey-violet. True black and white are saved for effect.

## Photos

- **Shape:** an arch. When the image is wider than 1.05× its height, use a
  shallow arch (rise = min(width ÷ 6, height × 0.28)). A capsule is the third
  choice.
- **Edge:** grown from the photo. Stretched strands go underneath, datamosh
  blocks sit near the image, and a few loose grains go on top.
- **Outline:** the outer outline is a smooth curve with a little noise in its
  width. Only the texture inside the border is pixelated.
- **Color:** graded by default. Muted purple and dusk purple stay as options.
- **Width:** at least 12px, scaled with image size.
- **Resolution:** rendered at 2× so phone screens stay sharp.
- **Small sizes:** the grown edge does not read at avatar size. Small
  thumbnails get the plain arch.

## Screens and UI

- **Shape:** screens never get a grown edge. They keep a nearly square shape,
  either a very shallow lintel (rise ≈ width ÷ 28) or a 3% corner radius.
- **Background:** each screen sits on a generated field made from the
  screenshot's own pixels.
- **Default field:** **Growth** (pending Z's pick). Pixel cells grow out from
  the screen's edge, each taking its parent's color with a small shift.
  **Drag** is the alternate: the screen's content pulled outward in broken
  pixel runs, the same process as the photo edge.
- **Defaults:** grade 100%, contrast 50%, density 50, variation 50%, margin 18%
  of the screen width.
- **Noise fields that worked** (fallbacks): dither, Bayer field, pixel,
  contours, terrain, marble, moiré.
- **Rejected:** orbit, weave, filament, warp, fold, tiles, stipple, fine
  grain.

## Revisit later

Each item is also in `BACKLOG.md` under **Media treatment**.

1. **Tune the screen fields.** On mostly-white screenshots, Echo and
   Compression come out washed out. Try per-field defaults for grade and
   variation in the mock's Field lab, then copy the chosen settings here.
2. **Pick the photo tint.** Graded is the default. Decide between graded and
   muted purple after seeing real case-study photos.
3. **Settle the border width.** Widths from 2 to 20px were tried and 12px is
   the floor. Confirm the scale rule on real figure sizes.
4. **Test distraction in real content.** Z's open worry is that the treatment
   pulls attention from the work. Judge it on a real case study, not sample
   copy.
5. **Decide small-size behaviour.** Cards and avatars need a rule for where
   the grown edge turns off.
6. **Choose where rendering happens.** Rendering in the browser costs
   JavaScript the page budget can't afford. The likely answer is rendering
   each image once at publish time and serving it as a file. Confirm against
   `page-weight.md`.
7. **Light theme.** Everything so far was judged on the dark theme.
8. **Real seeds.** Rerun with Z's raw Figma exports. Images must come without
   frames or backgrounds.

## Where things are

- Prototype source: [`media-prototype/`](../media-prototype/).
- Published sketches (private to Z): Grown Borders
  `https://claude.ai/artifact/D18giLKBrg8qGH3a4hdESJ` and Case Study Mock
  `https://claude.ai/artifact/X75KzStUw9tWM696dkv8iV`.
- Earlier media study on Z's Mac:
  `~/Documents/kimi/tasks/2026-10-24/10-02-43-f719765c/media-system-study`.
