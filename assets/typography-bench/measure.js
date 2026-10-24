(() => {
  const rect = (r) => ({
    x: r.x,
    y: r.y,
    width: r.width,
    height: r.height,
    top: r.top,
    bottom: r.bottom,
    left: r.left,
    right: r.right,
  });
  const properties = [
    "fontFamily",
    "fontSize",
    "fontWeight",
    "fontStyle",
    "fontStretch",
    "fontVariationSettings",
    "fontSizeAdjust",
    "lineHeight",
    "marginTop",
    "marginBottom",
    "paddingTop",
    "paddingBottom",
    "transform",
    "display",
    "overflow",
    "letterSpacing",
  ];
  function describe(el) {
    const style = getComputedStyle(el),
      box = el.getBoundingClientRect();
    const range = document.createRange();
    range.selectNodeContents(el);
    const canvas = document.createElement("canvas"),
      ctx = canvas.getContext("2d");
    ctx.font = `${style.fontStyle} ${style.fontWeight} ${style.fontSize} ${style.fontFamily}`;
    const text = el.textContent.trim(),
      m = ctx.measureText(text);
    return {
      name: el.id || el.dataset.part || el.className,
      tag: el.tagName,
      box: rect(box),
      style: Object.fromEntries(properties.map((p) => [p, style[p]])),
      contentRects: Array.from(range.getClientRects(), rect),
      text,
      canvasDiagnostic: {
        advance: m.width,
        inkAscent: m.actualBoundingBoxAscent,
        inkDescent: m.actualBoundingBoxDescent,
        fontAscent: m.fontBoundingBoxAscent,
        fontDescent: m.fontBoundingBoxDescent,
        limitations:
          "Single canvas run; excludes DOM wrapping, size-adjust, nested transforms and optical wrapper corrections",
      },
      opticalVariables: Object.fromEntries(
        ["--_lh", "--_dt", "--_db"].map((p) => [p, style.getPropertyValue(p)]),
      ),
    };
  }
  async function measure() {
    await document.fonts.ready;
    const main = document.querySelector("#specimen");
    const elements = [
      main,
      ...main.querySelectorAll(
        "[data-part],.optical-adjustment,.weather-heading,.weather-mark,.weather-temperature,.weather-icon-slot,.weather-credit",
      ),
    ];
    const nodes = elements.map(describe),
      findings = [];
    const intended =
      document.querySelector("[data-part=text]") ||
      document.querySelector(".weather-temperature");
    const style = getComputedStyle(intended),
      family = style.fontFamily.split(",")[0].trim().replaceAll('"', "");
    const faces = Array.from(document.fonts).filter(
      (f) => f.family.replaceAll('"', "") === family,
    );
    if (!faces.length)
      findings.push({
        kind: "font-unverified",
        message: `No declared web face for ${family}; local/system fallback may be rendering.`,
      });
    const loads = await Promise.allSettled(faces.map((f) => f.load()));
    if (loads.some((r) => r.status === "rejected"))
      findings.push({
        kind: "font-load-failed",
        message: "An intended face failed to load.",
      });
    const label =
      document.querySelector("[data-part=label]") ||
      document.querySelector(".weather-heading");
    const lower =
      document.querySelector("[data-part=text]") ||
      document.querySelector(".weather-mark");
    const gap = label
      ? lower.getBoundingClientRect().top - label.getBoundingClientRect().bottom
      : null;
    if (main.dataset.mode === "stack" && gap !== null && Math.abs(gap) > 0.5)
      findings.push({
        kind: "unexpected-layout-gap",
        message: `Zero-gap stack has ${gap.toFixed(2)}px between label and text boxes.`,
      });
    if (document.documentElement.scrollWidth > innerWidth)
      findings.push({
        kind: "horizontal-overflow",
        message: "Specimen exceeds the selected viewport.",
      });
    const weightClass = Array.from(intended.classList).find((c) =>
      c.startsWith("fw-flexa-"),
    );
    if (
      weightClass &&
      !getComputedStyle(intended).getPropertyValue(`--${weightClass}`).trim()
    )
      findings.push({ kind: "missing-weight-token", message: weightClass });
    const wrapper = intended.querySelector(".optical-adjustment");
    let opticalDiagnostic = null;
    if (wrapper) {
      const fontSize = parseFloat(style.fontSize);
      const leading = parseFloat(style.lineHeight);
      const cjk = intended.dataset.textScript === "cjk";
      const cap = cjk ? 1 : parseFloat(style.getPropertyValue("--type-cap"));
      const referenceHeight = cap * fontSize;
      const range = document.createRange();
      range.selectNodeContents(wrapper);
      const lines = new Set(
        Array.from(range.getClientRects())
          .filter((r) => r.width > 0)
          .map((r) => r.top.toFixed(2)),
      ).size;
      const expectedHeight = referenceHeight + Math.max(0, lines - 1) * leading;
      const actualHeight = intended.getBoundingClientRect().height;
      opticalDiagnostic = {
        reference: cjk ? "ideographic body" : "cap height to baseline",
        referenceHeight,
        leading,
        interlineGap: leading - referenceHeight,
        lines,
        expectedHeight,
        actualHeight,
        heightError: actualHeight - expectedHeight,
        trimStart: parseFloat(
          getComputedStyle(intended, "::before").marginBottom,
        ),
        trimEnd: parseFloat(getComputedStyle(intended, "::after").marginTop),
        limitation:
          "Reference geometry, not visible-ink bounds. Descenders, accents and overshoot may extend outside it; CJK fallback requires visual review.",
      };
      if (!Number.isFinite(leading) || leading <= 0)
        findings.push({
          kind: "invalid-leading",
          message: "Leading must be a positive resolved length.",
        });
      if (Math.abs(opticalDiagnostic.heightError) > 1)
        findings.push({
          kind: "trim-height-mismatch",
          message: `Component differs from the reference height by ${opticalDiagnostic.heightError.toFixed(2)}px.`,
        });
    }
    const result = {
      schema: "typography-bench/v1",
      configuration: {
        ...main.dataset,
        locale: document.documentElement.lang,
        theme: document.documentElement.dataset.theme,
        fault: document.body.dataset.fault,
      },
      environment: {
        userAgent: navigator.userAgent,
        width: innerWidth,
        dpr: devicePixelRatio,
        rootFontSize: getComputedStyle(document.documentElement).fontSize,
      },
      nodes,
      opticalDiagnostic,
      documentHeight: Math.max(
        72,
        Math.ceil(main.getBoundingClientRect().bottom + 24),
      ),
      gaps: { labelToText: gap },
      fontEvidence: {
        requestedFamily: family,
        declaredFaces: faces.map((f) => ({
          family: f.family,
          weight: f.weight,
          status: f.status,
        })),
        resources: performance
          .getEntriesByType("resource")
          .filter((r) => /\.(woff2?|ttf|otf)(\?|$)/.test(r.name))
          .map((r) => ({
            url: r.name,
            duration: r.duration,
            transferSize: r.transferSize,
          })),
        actualGlyphFont: "unverified — browser font inspection needed",
      },
      findings,
      verdict: findings.length
        ? "findings"
        : "structural checks passed; optical review needed",
    };
    window.benchResult = result;
    return result;
  }
  window.benchMeasure = measure;
  window.benchInspect = (index) => {
    window.benchOutline(false);
    const main = document.querySelector("#specimen");
    const elements = [
      main,
      ...main.querySelectorAll(
        "[data-part],.optical-adjustment,.weather-heading,.weather-mark,.weather-temperature,.weather-icon-slot,.weather-credit",
      ),
    ];
    elements[index].style.outline = "2px solid #e7926b";
  };
  window.benchOutline = (enabled) => {
    document
      .querySelectorAll(
        "[data-part],.optical-adjustment,.weather-mark,.weather-temperature,.weather-icon-slot,.weather-heading,.weather-credit",
      )
      .forEach((el) => {
        const typography = el.classList.contains("typography");
        el.style.outline =
          enabled && !el.classList.contains("optical-adjustment")
            ? "1px solid #e7926b"
            : "";
        if (typography) {
          const style = getComputedStyle(el);
          const cap =
            el.dataset.textScript === "cjk"
              ? 1
              : parseFloat(style.getPropertyValue("--type-cap"));
          const body = cap * parseFloat(style.fontSize);
          const leading = parseFloat(style.lineHeight);
          el.style.backgroundImage = enabled
            ? `repeating-linear-gradient(to bottom, transparent 0px, transparent ${Math.max(0, body - 0.5)}px, #70c4e080 ${body}px, transparent ${body + 0.5}px, transparent ${leading}px)`
            : "";
        }
        el.title = el.dataset.part || el.className;
      });
  };
  measure().then((r) =>
    parent.postMessage(
      {
        type: "typography-measured",
        request: new URLSearchParams(location.search).get("request"),
        result: r,
      },
      location.origin,
    ),
  );
})();
