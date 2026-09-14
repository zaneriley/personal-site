const articleView =
  new URLSearchParams(location.search).get("view") === "article";
const stressView =
  new URLSearchParams(location.search).get("view") === "stress";
const $ = (id) => document.getElementById(id);
let manifest,
  results = [],
  stopped = false,
  outlined = !articleView;
const labels = {
  font: "Typography role",
  size: "Size token",
  weight: "Weight role",
  locale: "Language",
  sample: "Text specimen",
  mode: "Composition",
  theme: "Theme",
  width: "Viewport width",
  fault: "Injected fault",
};
function select(name, values, initial) {
  const label = document.createElement("label");
  label.textContent = labels[name];
  const el = document.createElement("select");
  el.id = name;
  for (const value of values) {
    const option = document.createElement("option");
    option.value = value;
    option.textContent =
      {
        en: "English",
        ja: "日本語 · Japanese",
        mono: "GT Flexa Mono",
        flexa: "GT Flexa",
        cheee: "Cheee Small",
        cardinal: "Cardinal",
        noto: "Noto",
        caps: "Capitals / Japanese characters",
        descenders: "Ascenders & descenders",
        punctuation: "Punctuation & accents",
        mixed: "Mixed English / 日本語",
        paragraph: "Paragraph",
        single: "Single text",
        stack: "Tokyo / text / credit",
        weather: "Actual weather component",
        article: "Blog composition",
        auto: "Fit this screen",
      }[value] || value;
    el.append(option);
  }
  const requested = new URLSearchParams(location.search).get(name);
  el.value = values.includes(requested) ? requested : initial;
  label.append(el);
  (["font", "weight", "locale", "theme"].includes(name)
    ? $("controls")
    : $("advanced-controls")
  ).append(label);
}
function configuration() {
  return Object.fromEntries(Object.keys(labels).map((k) => [k, $(k).value]));
}
let requestId = 0;
const pending = new WeakMap();
function summary(report) {
  const node =
    report.nodes.find((n) => n.name === "text") ||
    report.nodes.find((n) => n.name.includes("weather-temperature"));
  const geometry = node
    ? `${parseFloat(node.style.fontSize).toFixed(1)}px type · ${node.box.height.toFixed(1)}px component · weight ${node.style.fontWeight}`
    : "";
  const optical = report.opticalDiagnostic;
  return [
    `CSS family: ${report.fontEvidence.requestedFamily}.`,
    geometry,
    optical
      ? `${optical.reference}: ${optical.referenceHeight.toFixed(2)}px · leading ${optical.leading.toFixed(2)}px · interline gap ${optical.interlineGap.toFixed(2)}px · ${optical.lines} lines · box error ${optical.heightError.toFixed(2)}px.`
      : "",
    ...report.findings.map((f) => f.message),
  ]
    .filter(Boolean)
    .join(" ");
}
async function render(config, frame = $("specimen-frame")) {
  pending.get(frame)?.();
  const id = String(++requestId);
  const width =
    config.width === "auto"
      ? frame.parentElement.clientWidth
      : Number(config.width);
  frame.style.width = `${width}px`;
  const url = new URL("/typography-bench/specimen", location.origin);
  for (const [k, v] of Object.entries(config)) url.searchParams.set(k, v);
  url.searchParams.set("request", id);
  return new Promise((resolve, reject) => {
    function cleanup() {
      clearTimeout(timeout);
      window.removeEventListener("message", receive);
      pending.delete(frame);
    }
    const timeout = setTimeout(() => {
      cleanup();
      reject(Error("Specimen timed out"));
    }, 15000);
    pending.set(frame, () => {
      cleanup();
      resolve(null);
    });
    function receive(event) {
      if (
        event.origin !== location.origin ||
        event.source !== frame.contentWindow ||
        event.data?.type !== "typography-measured" ||
        event.data.request !== id
      )
        return;
      cleanup();
      const report = {
        ...event.data.result,
        requested: { ...config, width: String(width) },
      };
      frame.style.height = `${Math.ceil(report.documentHeight)}px`;
      frame.contentWindow.benchOutline(outlined && frame !== $("matrix-frame"));
      if (frame === $("specimen-frame")) {
        $("evidence").textContent = JSON.stringify(report, null, 2);
        $("diagnosis").textContent = summary(report);
        $("boundary").replaceChildren();
        for (const [index, node] of report.nodes.entries()) {
          const option = document.createElement("option");
          option.value = index;
          option.textContent = `${node.name} (${node.tag})`;
          $("boundary").append(option);
        }
      }
      resolve(report);
    }
    window.addEventListener("message", receive);
    frame.src = url.href;
  });
}
let revision = 0;
async function refresh() {
  const current = ++revision;
  const config = configuration();
  if (articleView) config.mode = "article";
  $("status").textContent = "Updating…";
  const cards = [
    ...document.querySelectorAll("#sink iframe, #stress-cases iframe"),
  ];
  await Promise.all([
    ...(stressView ? [] : [render(config)]),
    ...cards.map(async (frame) => {
      const report = await render(
        {
          ...config,
          size: frame.dataset.size || config.size,
          sample: frame.dataset.sample || config.sample,
          locale: frame.dataset.locale || config.locale,
          mode: "single",
          width: "auto",
        },
        frame,
      );
      if (report && current === revision)
        frame.nextElementSibling.textContent = summary(report);
    }),
  ]);
  if (current === revision)
    $("status").textContent = "Ready · changes apply automatically";
}
function row(report) {
  const tr = document.createElement("tr");
  const config = report.requested;
  const cells = [
    `${config.font}/${config.size}/${config.weight}/${config.locale}/${config.sample}`,
    report.verdict,
    report.findings.map((f) => f.message).join(" · "),
  ];
  for (const text of cells) {
    const td = document.createElement("td");
    td.textContent = text;
    tr.append(td);
  }
  tr.className = report.findings.length ? "fail" : "review";
  const td = document.createElement("td"),
    button = document.createElement("button");
  button.textContent = "Inspect";
  button.onclick = () => {
    for (const [k, v] of Object.entries(config)) if ($(k)) $(k).value = v;
    refresh().catch(fail);
    $("specimen-frame").scrollIntoView({ block: "center" });
  };
  td.append(button);
  tr.append(td);
  $("results").append(tr);
}
function fail(error) {
  $("status").textContent = error.message;
}
async function run() {
  stopped = false;
  results = [];
  $("results").replaceChildren();
  $("run").disabled = true;

  $("stop").disabled = false;
  const sizes =
    $("scope").value === "small" ? ["3xs", "2xs", "1xs"] : manifest.sizes;
  const base = {
    ...configuration(),
    width: String(
      (stressView
        ? document.querySelector("#stress-cases iframe")
        : $("specimen-frame")
      ).clientWidth,
    ),
  };
  const total =
    manifest.options.fonts.length *
    sizes.length *
    manifest.weights.length *
    manifest.locales.length *
    manifest.specimens.length;
  try {
    for (const font of manifest.options.fonts)
      for (const size of sizes)
        for (const weight of manifest.weights)
          for (const locale of manifest.locales)
            for (const sample of manifest.specimens) {
              if (stopped) return;
              const config = {
                ...base,
                font,
                size,
                weight,
                locale,
                sample,
                mode: "stack",
                fault: "none",
              };
              let report;
              if (!manifest.options.sizes.includes(size)) {
                report = {
                  requested: config,
                  verdict: "unsupported",
                  findings: [
                    {
                      kind: "unsupported-size",
                      message:
                        "Generated token is not exposed by Typography component.",
                    },
                  ],
                };
              } else {
                try {
                  report = await render(config, $("matrix-frame"));
                } catch (error) {
                  report = {
                    requested: config,
                    verdict: "measurement failed",
                    findings: [
                      { kind: "measurement-failed", message: error.message },
                    ],
                  };
                }
              }
              results.push(report);
              row(report);
              $("coverage").textContent =
                `${results.length}/${total} measured or accounted for · ${results.filter((r) => r.findings.length).length} with findings · remaining ${total - results.length}. Width ${base.width}, theme ${base.theme}, current browser only.`;
            }
  } finally {
    $("run").disabled = false;

    $("stop").disabled = true;
    $("status").textContent = stopped
      ? "Stopped; incomplete coverage retained."
      : "Run complete; optical review remains.";
  }
}

$("boundary").onchange = () => {
  const frame = $("specimen-frame");
  const index = Number($("boundary").value);
  frame.contentWindow.benchInspect(index);
  $("evidence").textContent = JSON.stringify(
    frame.contentWindow.benchResult.nodes[index],
    null,
    2,
  );
};
$("outline").onclick = () => {
  outlined = !outlined;
  for (const frame of [
    $("specimen-frame"),
    ...document.querySelectorAll("#sink iframe, #stress-cases iframe"),
  ])
    frame.contentWindow.benchOutline?.(outlined);
  $("outline").setAttribute("aria-pressed", String(outlined));
  $("outline").textContent = outlined ? "Hide boxes" : "Show boxes";
};
$("run").onclick = () => run().catch(fail);
$("stop").onclick = () => {
  stopped = true;
};
$("export").onclick = () => {
  const data = {
    schema: "typography-bench-run/v1",
    createdAt: new Date().toISOString(),
    manifest,
    selected: $("specimen-frame").contentWindow.benchResult,
    stressCases: [...document.querySelectorAll("#stress-cases iframe")].map(
      (f) => f.contentWindow.benchResult,
    ),
    results,
  };
  const url = URL.createObjectURL(
    new Blob([JSON.stringify(data, null, 2)], { type: "application/json" }),
  );
  const a = document.createElement("a");
  a.href = url;
  a.download = "typography-bench.json";
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
};
fetch("/typography-bench/manifest")
  .then((r) => r.json())
  .then(async (m) => {
    manifest = m;
    $("manifest").textContent = JSON.stringify(m, null, 2);
    select("font", m.options.fonts, articleView ? "cardinal" : "flexa");
    select(
      "size",
      [...m.sizes].reverse().filter((s) => m.options.sizes.includes(s)),
      "md",
    );
    select("weight", m.weights, "regular");
    select("locale", m.locales, "en");
    select("sample", m.specimens, "paragraph");
    select(
      "mode",
      ["single", "stack", "weather", "article"],
      articleView ? "article" : "single",
    );
    select("theme", ["dark", "light"], "dark");
    select("width", ["auto", "320", "390", "768", "1280"], "auto");
    select("fault", ["none", "margin", "font"], "none");
    if (!stressView && !articleView)
      for (const size of [...m.sizes]
        .reverse()
        .filter((s) => m.options.sizes.includes(s))) {
        const card = document.createElement("article");
        card.className = "card";
        const title = document.createElement("header");
        title.textContent = size;
        const frame = document.createElement("iframe");
        frame.title = `${size} typography specimen`;
        frame.dataset.size = size;
        const output = document.createElement("output");
        card.append(title, frame, output);
        $("sink").append(card);
      }
    if (articleView) {
      $("sink").closest("section").hidden = true;
      $("selected-title").querySelector("h2").textContent =
        "Reading composition";
      $("font").parentElement.firstChild.textContent = "Heading role";
      $("outline").textContent = "Show boxes";
      $("outline").setAttribute("aria-pressed", "false");
      for (const name of ["size", "sample", "mode", "fault"])
        $(name).parentElement.hidden = true;
    }
    if (stressView) {
      $("specimen-frame").closest("section").hidden = true;
      $("sink").closest("section").hidden = true;
      $("stress-review").hidden = false;
      $("locale").parentElement.hidden = true;
      $("controls").append($("size").parentElement);
      $("stress-heading").append($("outline"));
      for (const specimen of m.stress_cases) {
        const section = document.createElement("div");
        section.className = "stress-case";
        const heading = document.createElement("h3");
        heading.textContent = specimen.title;
        const prompt = document.createElement("div");
        prompt.className = "muted";
        prompt.textContent = specimen.inspect;
        const pair = document.createElement("div");
        pair.className = "stress-pair";
        for (const locale of ["en", "ja"]) {
          const card = document.createElement("article");
          card.className = "card";
          const title = document.createElement("header");
          title.textContent =
            locale === "en"
              ? "Latin rhythm · cap → baseline"
              : "CJK rhythm · ideographic body";
          const frame = document.createElement("iframe");
          frame.title = `${specimen.title} · ${locale}`;
          frame.dataset.sample = specimen.id;
          frame.dataset.locale = locale;
          const output = document.createElement("output");
          card.append(title, frame, output);
          pair.append(card);
        }
        section.append(heading, prompt, pair);
        $("stress-cases").append(section);
      }
    }
    for (const key of Object.keys(labels))
      $(key).onchange = () => refresh().catch(fail);
    let resizeTimer;
    window.addEventListener("resize", () => {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(() => refresh().catch(fail), 150);
    });
    await refresh();
  })
  .catch(fail);
