# Media treatment prototypes

Browser sketches behind [`_PROJECT_DOCS/media-treatment.md`](../_PROJECT_DOCS/media-treatment.md).
They are reference code for tuning the treatment later, not part of the app
build.

- `grown-borders.template.html` — grows a border out of a photo's own pixels
  (stretch, datamosh, layered), with shapes, tints, widths and sizes.
- `case-study-mock.template.html` — a sample case-study page that shows photos
  with grown edges and screens on generated fields. The **Field lab** panel
  holds every screen field and its sliders.
- `study-generators.js` — the twelve noise-field generators from the earlier
  media study, wrapped as one `STUDY` object.

The templates leave out their images. To run one, replace its placeholders:

- `__IMAGES__` in the grown-borders template: a JSON object mapping seed ids
  (`portrait`, `page`, `terrain`, `leaves`, `crowd`, `pixel`, `clinic`,
  `home`) to data URIs.
- `__RAW__` in the mock: a JSON object of raw image data URIs (`portrait`,
  `terrain`, `leaves`, `page`, `clinic`, `home`).
- `__GROWN__` in the mock: a JSON object of pre-rendered photo edges from the
  grown-borders sketch, named `<photo>-<graded|muted|dusk>` and rendered at 2×.
- `__STUDY__` in the mock: the contents of `study-generators.js`, minus its
  leading `const STUDY = ` and trailing `;`.

Seeds must be raw images with no Figma background or frame.
