#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptPath = fileURLToPath(import.meta.url);
const repoRoot = path.resolve(path.dirname(scriptPath), "../..");
const args = process.argv.slice(2);

const outputRoot = resolveRepoPath(
  optionValue(args, "--output-root", ".tmp/ci-artifacts/perf-audit"),
);
const routeLatencyPath = resolveRepoPath(
  optionValue(
    args,
    "--route-latency",
    ".tmp/ci-artifacts/prod-build/route-latency-last-run.json",
  ),
);
const browserPerformancePath = resolveRepoPath(
  optionValue(
    args,
    "--browser-performance",
    ".tmp/ci-artifacts/prod-build/browser-performance-last-run.json",
  ),
);
const runtimePath = resolveRepoPath(
  optionValue(args, "--runtime", ".tmp/ci-artifacts/prod-build/runtime-last-run.json"),
);

const generatedAt = new Date();
const runId = generatedAt
  .toISOString()
  .replace(/\.\d{3}Z$/, "Z")
  .replaceAll(/[-:]/g, "");
const outputDir = path.join(outputRoot, runId);

const [routeLatency, browserPerformance, runtime] = await Promise.all([
  readJson(routeLatencyPath),
  readJson(browserPerformancePath),
  readJson(runtimePath),
]);

const audit = buildAudit({
  generatedAt: generatedAt.toISOString(),
  routeLatency,
  browserPerformance,
  runtime,
});
const summary = renderSummary(audit);

await fs.mkdir(outputDir, { recursive: true });
await fs.writeFile(path.join(outputDir, "perf-audit.json"), `${JSON.stringify(audit, null, 2)}\n`);
await fs.writeFile(path.join(outputDir, "summary.md"), summary);
await fs.writeFile(
  path.join(outputRoot, "latest-summary.md"),
  `# Latest Performance Audit\n\nSee [${runId}/summary.md](${runId}/summary.md).\n`,
);

console.log(`performance audit written: ${path.relative(repoRoot, outputDir)}/summary.md`);

function buildAudit({ generatedAt: auditGeneratedAt, routeLatency, browserPerformance, runtime }) {
  const routes = Object.entries(browserPerformance.routes ?? {}).map(([routePath, route]) => {
    const latency = routeLatency.routes?.[routePath] ?? {};
    const thresholds = route.thresholds ?? {};
    const observed = {
      total_bytes: route.resources?.total_bytes ?? null,
      html_bytes: route.resources?.html_bytes ?? null,
      css_bytes: route.resources?.css_bytes ?? null,
      js_bytes: route.resources?.js_bytes ?? null,
      font_bytes: route.resources?.font_bytes ?? null,
      image_bytes: route.resources?.image_bytes ?? null,
      request_count: route.resources?.request_count ?? null,
      websocket_total_bytes: route.resources?.websocket_total_bytes ?? null,
      readable_content_ms: route.metrics?.readable_content_ms ?? null,
      dom_content_loaded_ms: route.metrics?.dom_content_loaded_ms ?? null,
      load_ms: route.metrics?.load_ms ?? null,
      fcp_ms: route.metrics?.fcp_ms ?? null,
      lcp_ms: route.metrics?.lcp_ms ?? null,
      cls: route.metrics?.cls ?? null,
      cold_first_ms: latency.cold_first_ms ?? null,
      warm_p50_ms: latency.warm_p50_ms ?? null,
      warm_p95_ms: latency.warm_p95_ms ?? null,
    };

    return {
      label: route.label,
      path: routePath,
      status: route.status,
      http_status: route.http_status,
      observed,
      thresholds,
      largest_resources: route.resources?.largest_resources ?? [],
    };
  });

  const memory = memorySummary(runtime);
  const headline = {
    app_sha: runtime.app_sha ?? browserPerformance.app_sha ?? routeLatency.app_sha ?? null,
    content_fixture_sha256: runtime.content?.fixture_sha256 ?? null,
    image_id: runtime.image?.id ?? null,
    local_image_disk_size_bytes: runtime.image?.local_image_disk_size_bytes ?? null,
    ready_ms: routeLatency.ready_ms ?? null,
    max_total_bytes: maxObserved(routes, "total_bytes"),
    max_js_bytes: maxObserved(routes, "js_bytes"),
    max_websocket_bytes: maxObserved(routes, "websocket_total_bytes"),
    max_warm_p95_ms: maxObserved(routes, "warm_p95_ms"),
    max_lcp_ms: maxObserved(routes, "lcp_ms"),
    memory_sample_count: memory.sample_count,
    memory_min_bytes: memory.min_bytes,
    memory_median_bytes: memory.median_bytes,
    memory_max_bytes: memory.max_bytes,
    memory_min: formatBytes(memory.min_bytes),
    memory_median: formatBytes(memory.median_bytes),
    memory_max: formatBytes(memory.max_bytes),
  };

  return {
    schema_version: 1,
    command: "ci:perf-audit",
    generated_at: auditGeneratedAt,
    source_command: "ci:prod-build",
    status:
      browserPerformance.status === "pass" &&
      routeLatency.status !== "fail"
        ? "pass"
        : "review",
    headline,
    memory,
    runtime,
    routes,
    budget_tightening_candidates: globalTighteningCandidates(routes),
    largest_first_load_resources: largestFirstLoadResources(routes),
  };
}

function globalTighteningCandidates(routes) {
  const metricMap = [
    ["total_bytes", "max_total_bytes", { kind: "bytes", floor: 80_000 }],
    ["html_bytes", "max_html_bytes", { kind: "bytes", floor: 30_000 }],
    ["css_bytes", "max_css_bytes", { kind: "bytes", floor: 10_000 }],
    ["js_bytes", "max_js_bytes", { kind: "bytes", floor: 60_000 }],
    ["request_count", "max_request_count", { kind: "count", floor: 6 }],
    ["websocket_total_bytes", "max_websocket_bytes", { kind: "bytes", floor: 20_000 }],
    ["readable_content_ms", "max_readable_content_ms", { kind: "ms", floor: 500 }],
    ["dom_content_loaded_ms", "max_dom_content_loaded_ms", { kind: "ms", floor: 500 }],
    ["load_ms", "max_load_ms", { kind: "ms", floor: 1_000 }],
    ["fcp_ms", "max_fcp_ms", { kind: "ms", floor: 1_000 }],
  ];

  return metricMap
    .map(([observedMetric, thresholdMetric, rule]) => {
      const observedValues = routes
        .map((route) => route.observed[observedMetric])
        .filter((value) => Number.isFinite(value));
      const thresholdValues = routes
        .map((route) => route.thresholds[thresholdMetric])
        .filter((value) => Number.isFinite(value));

      if (observedValues.length === 0 || thresholdValues.length === 0) {
        return null;
      }

      const observedMax = Math.max(...observedValues);
      const currentBudget = Math.max(...thresholdValues);

      if (observedMax === 0 || observedMax > currentBudget * 0.8) {
        return null;
      }

      const suggested = Math.max(
        rule.floor,
        roundedBudget(observedMax * 1.25, rule.kind),
      );

      if (suggested >= currentBudget) {
        return null;
      }

      return {
        metric: observedMetric,
        observed_max: observedMax,
        current_budget: currentBudget,
        suggested_budget: suggested,
      };
    })
    .filter(Boolean);
}

function roundedBudget(value, kind) {
  if (kind === "count") {
    return Math.ceil(value);
  }

  if (kind === "ms") {
    return Math.ceil(value / 100) * 100;
  }

  return Math.ceil(value / 1000) * 1000;
}

function largestFirstLoadResources(routes) {
  return routes.flatMap((route) =>
    route.largest_resources.slice(0, 3).map((resource) => ({
      route: route.path,
      url: resource.url,
      category: resource.category,
      bytes: resource.bytes,
    })),
  );
}

function renderSummary(audit) {
  const lines = [];
  const headline = audit.headline;

  lines.push("# Performance Audit");
  lines.push("");
  lines.push(`Generated: ${audit.generated_at}`);
  lines.push(`Source: ${audit.source_command}`);
  lines.push(`App SHA: ${headline.app_sha ?? "unknown"}`);
  lines.push(`Content fixture SHA-256: ${headline.content_fixture_sha256 ?? "unknown"}`);
  lines.push(`Image ID: ${shortSha(headline.image_id)}`);
  lines.push("");
  lines.push("## Headline");
  lines.push("");
  lines.push("| Measure | Observed |");
  lines.push("| --- | ---: |");
  lines.push(`| Ready time | ${formatMs(headline.ready_ms)} |`);
  lines.push(`| Max warm p95 route latency | ${formatMs(headline.max_warm_p95_ms)} |`);
  lines.push(`| Max total page bytes | ${formatBytes(headline.max_total_bytes)} |`);
  lines.push(`| Max JavaScript bytes | ${formatBytes(headline.max_js_bytes)} |`);
  lines.push(`| Max WebSocket bytes | ${formatBytes(headline.max_websocket_bytes)} |`);
  lines.push(`| Max LCP | ${formatMs(headline.max_lcp_ms)} |`);
  lines.push(
    `| Memory usage (${formatNumber(headline.memory_sample_count)} samples, min / median / max) | ${headline.memory_min} / ${headline.memory_median} / ${headline.memory_max} |`,
  );
  lines.push(`| Local image disk size | ${formatBytes(headline.local_image_disk_size_bytes)} |`);
  lines.push("");
  lines.push("## Routes");
  lines.push("");
  lines.push(
    "| Route | Total | JS | HTML | WS | Requests | Readable | Load | LCP | Warm p95 |",
  );
  lines.push("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |");

  for (const route of audit.routes) {
    const observed = route.observed;
    lines.push(
      `| ${route.path} | ${formatBytes(observed.total_bytes)} | ${formatBytes(observed.js_bytes)} | ${formatBytes(observed.html_bytes)} | ${formatBytes(observed.websocket_total_bytes)} | ${formatNumber(observed.request_count)} | ${formatMs(observed.readable_content_ms)} | ${formatMs(observed.load_ms)} | ${formatMs(observed.lcp_ms)} | ${formatMs(observed.warm_p95_ms)} |`,
    );
  }

  lines.push("");
  lines.push("## Budget Headroom");
  lines.push("");
  lines.push(
    "These are local prod-build measurements. Browser timing numbers are loopback checks, useful for catching large regressions, not real-world network latency.",
  );
  lines.push("");
  lines.push("| Metric | Worst observed | Budget | Headroom |");
  lines.push("| --- | ---: | ---: | ---: |");

  for (const row of budgetHeadroomRows(audit.routes)) {
    lines.push(
      `| ${row.metric} | ${formatMetric(row.metric, row.observed)} | ${formatMetric(row.metric, row.budget)} | ${row.headroom} |`,
    );
  }

  if (audit.budget_tightening_candidates.length > 0) {
    lines.push("");
    lines.push("Additional tightening candidates:");

    for (const candidate of audit.budget_tightening_candidates) {
      lines.push(
        `- ${candidate.metric}: ${formatMetric(candidate.metric, candidate.observed_max)} observed, ${formatMetric(candidate.metric, candidate.suggested_budget)} suggested`,
      );
    }
  }

  lines.push("");
  lines.push("## Largest First-Load Resources");
  lines.push("");
  lines.push("| Route | Resource | Category | Bytes |");
  lines.push("| --- | --- | --- | ---: |");

  for (const resource of audit.largest_first_load_resources) {
    lines.push(
      `| ${resource.route} | ${formatResourceUrl(resource.url)} | ${resource.category} | ${formatBytes(resource.bytes)} |`,
    );
  }

  lines.push("");
  lines.push("## Raw Inputs");
  lines.push("");
  lines.push("- `.tmp/ci-artifacts/prod-build/route-latency-last-run.json`");
  lines.push("- `.tmp/ci-artifacts/prod-build/browser-performance-last-run.json`");
  lines.push("- `.tmp/ci-artifacts/prod-build/runtime-last-run.json`");
  lines.push("- `perf-audit.json` in this directory");
  lines.push("");

  return `${lines.join("\n")}\n`;
}

function budgetHeadroomRows(routes) {
  const metricMap = [
    ["total_bytes", "max_total_bytes"],
    ["html_bytes", "max_html_bytes"],
    ["css_bytes", "max_css_bytes"],
    ["js_bytes", "max_js_bytes"],
    ["request_count", "max_request_count"],
    ["websocket_total_bytes", "max_websocket_bytes"],
    ["readable_content_ms", "max_readable_content_ms"],
    ["dom_content_loaded_ms", "max_dom_content_loaded_ms"],
    ["load_ms", "max_load_ms"],
    ["fcp_ms", "max_fcp_ms"],
  ];

  return metricMap.map(([observedMetric, thresholdMetric]) => {
    const observedValues = routes
      .map((route) => route.observed[observedMetric])
      .filter((value) => Number.isFinite(value));
    const thresholdValues = routes
      .map((route) => route.thresholds[thresholdMetric])
      .filter((value) => Number.isFinite(value));
    const observed = observedValues.length === 0 ? null : Math.max(...observedValues);
    const budget = thresholdValues.length === 0 ? null : Math.max(...thresholdValues);

    return {
      metric: observedMetric,
      observed,
      budget,
      headroom: Number.isFinite(observed) && Number.isFinite(budget)
        ? `${Math.round(((budget - observed) / budget) * 100)}%`
        : "n/a",
    };
  });
}

function memorySummary(runtime) {
  const samples = Object.values(runtime.snapshots ?? {})
    .map((snapshot) => {
      const usage = snapshot.docker_stats?.MemUsage?.split(" / ")[0] ?? null;
      const usageBytes = parseByteString(usage);

      if (!Number.isFinite(usageBytes)) {
        return null;
      }

      return {
        stage: snapshot.stage,
        captured_at: snapshot.captured_at,
        usage,
        usage_bytes: usageBytes,
      };
    })
    .filter(Boolean);

  if (samples.length === 0) {
    return {
      sample_count: 0,
      min_bytes: null,
      median_bytes: null,
      max_bytes: null,
      samples: [],
    };
  }

  const sortedSamples = [...samples].sort((left, right) => left.usage_bytes - right.usage_bytes);

  return {
    sample_count: samples.length,
    min_bytes: sortedSamples[0].usage_bytes,
    median_bytes: median(sortedSamples.map((sample) => sample.usage_bytes)),
    max_bytes: sortedSamples.at(-1).usage_bytes,
    samples,
  };
}

function median(values) {
  const middle = Math.floor(values.length / 2);

  return values.length % 2 === 1
    ? values[middle]
    : Math.round((values[middle - 1] + values[middle]) / 2);
}

function parseByteString(value) {
  const match = String(value).trim().match(/^([0-9.]+)([KMGT]?i?B)$/i);

  if (!match) {
    return null;
  }

  const amount = Number(match[1]);
  const unit = match[2].toLowerCase();
  const multipliers = {
    b: 1,
    kb: 1000,
    mb: 1000 ** 2,
    gb: 1000 ** 3,
    tb: 1000 ** 4,
    kib: 1024,
    mib: 1024 ** 2,
    gib: 1024 ** 3,
    tib: 1024 ** 4,
  };

  return Number.isFinite(amount) && multipliers[unit]
    ? Math.round(amount * multipliers[unit])
    : null;
}

function maxObserved(routes, metric) {
  const values = routes
    .map((route) => route.observed[metric])
    .filter((value) => Number.isFinite(value));

  return values.length === 0 ? null : Math.max(...values);
}

function shortSha(value) {
  if (!value) {
    return "unknown";
  }

  return value.replace(/^sha256:/, "").slice(0, 12);
}

function formatMetric(metric, value) {
  if (metric.includes("bytes")) {
    return formatBytes(value);
  }

  if (metric.endsWith("_ms")) {
    return formatMs(value);
  }

  return formatNumber(value);
}

function formatBytes(value) {
  if (!Number.isFinite(value)) {
    return "n/a";
  }

  return `${value.toLocaleString("en-US")} B`;
}

function formatMs(value) {
  if (!Number.isFinite(value)) {
    return "n/a";
  }

  return `${value.toLocaleString("en-US")} ms`;
}

function formatNumber(value) {
  if (!Number.isFinite(value)) {
    return "n/a";
  }

  return value.toLocaleString("en-US");
}

function formatResourceUrl(value) {
  try {
    return new URL(value).pathname;
  } catch (_error) {
    return value ?? "n/a";
  }
}

function optionValue(argumentList, name, fallback) {
  const index = argumentList.indexOf(name);

  if (index === -1) {
    return fallback;
  }

  const value = argumentList[index + 1];

  if (!value || value.startsWith("--")) {
    throw new Error(`Missing value for ${name}`);
  }

  return value;
}

function resolveRepoPath(filePath) {
  return path.isAbsolute(filePath) ? filePath : path.join(repoRoot, filePath);
}

async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, "utf8"));
}
