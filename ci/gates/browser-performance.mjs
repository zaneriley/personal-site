#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium, devices } from "playwright";

const scriptPath = fileURLToPath(import.meta.url);
const repoRoot = path.resolve(path.dirname(scriptPath), "../..");

const args = process.argv.slice(2);
const outputPath = optionValue(
  args,
  "--output",
  process.env.PERF_BROWSER_OUTPUT ??
    ".tmp/ci-artifacts/prod-build/browser-performance-last-run.json",
);
const budgetPath = optionValue(
  args,
  "--routes-contract",
  process.env.PERF_BROWSER_ROUTES_CONTRACT ?? "ci/contracts/routes.json",
);
const baseUrl = normalizeBaseUrl(
  optionValue(
    args,
    "--base-url",
    process.env.PERF_BROWSER_BASE_URL ??
      process.env.PROD_BUILD_BASE_URL ??
      "http://127.0.0.1:18080",
  ),
);
const appSha = process.env.PROD_BUILD_APP_SHA ?? currentAppSha();
const budget = normalizePerformanceContract(await readJson(resolveRepoPath(budgetPath)));
const baseOrigin = new URL(baseUrl).origin;
const failures = [];
const warnings = [];
const routes = {};

validateBudget(budget, failures);

const browser = await chromium.launch({ headless: true });

try {
  for (const routeBudget of budget.routes ?? []) {
    const routeResult = await measureRoute(browser, routeBudget);
    routes[routeBudget.path] = routeResult;
    failures.push(...routeResult.failures);
    warnings.push(...routeResult.warnings);
    printRouteSummary(routeResult);
  }
} finally {
  await browser.close();
}

const result = {
  schema_version: 1,
  command: "ci:performance-browser",
  generated_at: new Date().toISOString(),
  app_sha: appSha,
  base_url: baseUrl,
  profile: budget.profile ?? {},
  status: failures.length === 0 ? "pass" : "fail",
  failures,
  warnings,
  routes,
};

await writeResult(outputPath, result);

if (failures.length > 0) {
  printFailureSummary(result);
  process.exit(1);
}

printHuman("performance browser passed");

async function measureRoute(browserInstance, routeBudget) {
  const routeConfig = {
    ...(budget.defaults ?? {}),
    ...routeBudget,
  };
  const url = new URL(routeConfig.path, `${baseUrl}/`).toString();
  const routeFailures = [];
  const routeWarnings = [];
  const consoleErrors = [];
  const pageErrors = [];
  const requestFailures = [];
  const responses = [];
  const blockedExternalRequests = [];
  const webSockets = webSocketMetrics();
  const device = devices[budget.profile?.device] ?? devices["Pixel 5"];
  const context = await browserInstance.newContext({
    ...device,
    bypassCSP: true,
    javaScriptEnabled: true,
    serviceWorkers: "block",
  });

  await context.addInitScript(() => {
    window.__portfolioPerformance = {
      cls: 0,
      lcp_ms: null,
    };

    try {
      new PerformanceObserver((entryList) => {
        const entries = entryList.getEntries();
        const lastEntry = entries[entries.length - 1];

        if (lastEntry) {
          window.__portfolioPerformance.lcp_ms = lastEntry.startTime;
        }
      }).observe({ type: "largest-contentful-paint", buffered: true });
    } catch (_error) {
      window.__portfolioPerformance.lcp_ms = null;
    }

    try {
      new PerformanceObserver((entryList) => {
        for (const entry of entryList.getEntries()) {
          if (!entry.hadRecentInput) {
            window.__portfolioPerformance.cls += entry.value;
          }
        }
      }).observe({ type: "layout-shift", buffered: true });
    } catch (_error) {
      window.__portfolioPerformance.cls = null;
    }
  });

  const page = await context.newPage();

  page.on("console", (message) => {
    if (message.type() === "error") {
      consoleErrors.push({
        text: message.text(),
        location: message.location(),
      });
    }
  });

  page.on("pageerror", (error) => {
    pageErrors.push(error.message);
  });

  page.on("requestfailed", (request) => {
    requestFailures.push({
      url: request.url(),
      resource_type: request.resourceType(),
      failure: request.failure()?.errorText ?? "unknown request failure",
    });
  });

  page.on("response", (response) => {
    responses.push(response);
  });

  page.on("websocket", (socket) => {
    webSockets.opened += 1;
    webSockets.urls.add(socket.url());

    socket.on("framesent", (frame) => {
      webSockets.sent_frames += 1;
      webSockets.sent_bytes += payloadBytes(frame.payload);
    });

    socket.on("framereceived", (frame) => {
      webSockets.received_frames += 1;
      webSockets.received_bytes += payloadBytes(frame.payload);
    });
  });

  await page.route("**/*", async (route) => {
    const requestUrl = route.request().url();

    if (externalHttpRequest(requestUrl, baseOrigin)) {
      blockedExternalRequests.push(requestUrl);
      await route.abort();
      return;
    }

    await route.continue();
  });

  let mainResponse = null;
  let readableContentMs = null;
  let navigationError = null;

  try {
    mainResponse = await page.goto(url, {
      waitUntil: "domcontentloaded",
      timeout: routeConfig.timeout_ms,
    });

    await page.locator(routeConfig.main_selector).waitFor({
      state: "visible",
      timeout: routeConfig.timeout_ms,
    });

    readableContentMs = await page.evaluate(() =>
      Math.round(performance.now()),
    );
    await page.waitForLoadState("load", { timeout: routeConfig.timeout_ms });
    await page.waitForTimeout(routeConfig.settle_ms);
  } catch (error) {
    navigationError = error.message;
  }

  const metrics = await collectPageMetrics(page, readableContentMs, (error) => {
    navigationError = [navigationError, `metrics collection failed: ${error.message}`]
      .filter(Boolean)
      .join("; ");
  });
  const resources = await resourceMetrics(responses, baseOrigin, webSockets);
  const status = mainResponse?.status() ?? null;

  applyRouteAssertions({
    routeConfig,
    routeFailures,
    status,
    navigationError,
    consoleErrors,
    pageErrors,
    requestFailures,
    resources,
    metrics,
  });

  await context.close();

  return {
    label: routeConfig.label,
    path: routeConfig.path,
    url,
    status: routeFailures.length === 0 ? "pass" : "fail",
    http_status: status,
    final_url: mainResponse?.url() ?? null,
    metrics,
    resources,
    console_errors: consoleErrors,
    page_errors: pageErrors,
    request_failures: requestFailures,
    blocked_external_requests: blockedExternalRequests,
    thresholds: thresholdsFor(routeConfig),
    failures: routeFailures.map((failure) => ({
      route: routeConfig.path,
      ...failure,
    })),
    warnings: routeWarnings,
  };
}

async function pageMetrics(page, readableContentMs) {
  return await page.evaluate((readableMs) => {
    const navigation = performance.getEntriesByType("navigation")[0];
    const fcp = performance.getEntriesByName("first-contentful-paint")[0];
    const portfolioPerformance = window.__portfolioPerformance ?? {};

    return {
      readable_content_ms: readableMs,
      ttfb_ms: navigation
        ? Math.round(navigation.responseStart - navigation.requestStart)
        : null,
      dom_content_loaded_ms: navigation
        ? Math.round(navigation.domContentLoadedEventEnd - navigation.startTime)
        : null,
      load_ms: navigation
        ? Math.round(navigation.loadEventEnd - navigation.startTime)
        : null,
      fcp_ms: fcp ? Math.round(fcp.startTime) : null,
      lcp_ms:
        typeof portfolioPerformance.lcp_ms === "number"
          ? Math.round(portfolioPerformance.lcp_ms)
          : null,
      cls:
        typeof portfolioPerformance.cls === "number"
          ? Number(portfolioPerformance.cls.toFixed(4))
          : null,
    };
  }, readableContentMs);
}

async function collectPageMetrics(page, readableContentMs, onError) {
  try {
    return await pageMetrics(page, readableContentMs);
  } catch (error) {
    onError(error);
    return {
      readable_content_ms: readableContentMs,
      ttfb_ms: null,
      dom_content_loaded_ms: null,
      load_ms: null,
      fcp_ms: null,
      lcp_ms: null,
      cls: null,
    };
  }
}

async function resourceMetrics(responses, origin, webSockets) {
  const resources = {
    request_count: 0,
    total_bytes: 0,
    html_bytes: 0,
    css_bytes: 0,
    js_bytes: 0,
    font_bytes: 0,
    image_bytes: 0,
    other_bytes: 0,
    websocket_opened: webSockets.opened,
    websocket_sent_frames: webSockets.sent_frames,
    websocket_received_frames: webSockets.received_frames,
    websocket_sent_bytes: webSockets.sent_bytes,
    websocket_received_bytes: webSockets.received_bytes,
    websocket_total_bytes: webSockets.sent_bytes + webSockets.received_bytes,
    websocket_urls: Array.from(webSockets.urls).sort(),
    failed_statuses: [],
    missing_size_urls: [],
    largest_resources: [],
  };

  for (const response of responses) {
    const responseUrl = response.url();

    if (!sameOriginHttpRequest(responseUrl, origin)) {
      continue;
    }

    const status = response.status();
    const resourceType = response.request().resourceType();
    const headers = await response.allHeaders();
    const contentType = headers["content-type"] ?? "";
    const transferSize = await responseTransferSize(response);

    if (!transferSize) {
      resources.missing_size_urls.push({
        url: responseUrl,
        status,
        resource_type: resourceType,
      });
      continue;
    }

    const bytes = transferSize.total_bytes;
    const category = resourceCategory(resourceType, contentType, responseUrl);

    resources.request_count += 1;
    resources.total_bytes += bytes;
    resources[`${category}_bytes`] += bytes;

    resources.largest_resources.push({
      url: responseUrl,
      status,
      resource_type: resourceType,
      category,
      bytes,
      response_body_bytes: transferSize.response_body_bytes,
      response_header_bytes: transferSize.response_header_bytes,
    });

    if (status >= 400) {
      resources.failed_statuses.push({
        url: responseUrl,
        status,
        resource_type: resourceType,
      });
    }
  }

  resources.largest_resources = resources.largest_resources
    .sort((left, right) => right.bytes - left.bytes)
    .slice(0, 10);

  return resources;
}

async function responseTransferSize(response) {
  try {
    const sizes = await response.request().sizes();
    const bodyBytes = finiteNonNegative(sizes.responseBodySize);
    const headerBytes = finiteNonNegative(sizes.responseHeadersSize);

    if (bodyBytes === null || headerBytes === null) {
      return null;
    }

    return {
      total_bytes: bodyBytes + headerBytes,
      response_body_bytes: bodyBytes,
      response_header_bytes: headerBytes,
    };
  } catch (_error) {
    return null;
  }
}

function finiteNonNegative(value) {
  if (Number.isFinite(value) && value >= 0) {
    return value;
  }

  return null;
}

function webSocketMetrics() {
  return {
    opened: 0,
    sent_frames: 0,
    received_frames: 0,
    sent_bytes: 0,
    received_bytes: 0,
    urls: new Set(),
  };
}

function payloadBytes(payload) {
  if (typeof payload === "string") {
    return Buffer.byteLength(payload);
  }

  if (Buffer.isBuffer(payload)) {
    return payload.length;
  }

  return Buffer.byteLength(String(payload ?? ""));
}

function applyRouteAssertions({
  routeConfig,
  routeFailures,
  status,
  navigationError,
  consoleErrors,
  pageErrors,
  requestFailures,
  resources,
  metrics,
}) {
  if (navigationError) {
    routeFailures.push({
      code: "navigation_failed",
      problem: "Browser could not render the page",
      observed: navigationError,
      allowed: "page must load and expose visible main content",
    });
  }

  if (!routeConfig.allowed_statuses.includes(status)) {
    routeFailures.push({
      code: "unexpected_status",
      problem: "Page returned an unexpected status",
      observed: status,
      allowed: routeConfig.allowed_statuses,
    });
  }

  for (const metric of budget.required_metrics ?? []) {
    if (!Number.isFinite(metrics[metric])) {
      routeFailures.push({
        code: "missing_metric",
        problem: `Missing required browser metric ${metric}`,
        observed: metrics[metric],
        allowed: "finite number",
      });
    }
  }

  if (consoleErrors.length > 0) {
    routeFailures.push({
      code: "console_errors",
      problem: "Page emitted browser console errors",
      observed: consoleErrors.map((error) => error.text),
      allowed: "no console errors",
    });
  }

  if (pageErrors.length > 0) {
    routeFailures.push({
      code: "page_errors",
      problem: "Page emitted uncaught browser errors",
      observed: pageErrors,
      allowed: "no page errors",
    });
  }

  if (requestFailures.length > 0) {
    routeFailures.push({
      code: "request_failures",
      problem: "Page had failed network requests",
      observed: requestFailures,
      allowed: "no failed network requests",
    });
  }

  if (resources.failed_statuses.length > 0) {
    routeFailures.push({
      code: "failed_resource_status",
      problem: "Page loaded same-origin resources with failing HTTP statuses",
      observed: resources.failed_statuses,
      allowed: "all same-origin resources return < 400",
    });
  }

  if (resources.missing_size_urls.length > 0) {
    routeFailures.push({
      code: "missing_resource_size",
      problem: "Browser could not measure transferred bytes for resources",
      observed: resources.missing_size_urls,
      allowed: "all same-origin resources expose Playwright network sizes",
    });
  }

  compareBudget(
    routeFailures,
    "total_bytes",
    resources.total_bytes,
    routeConfig.max_total_bytes,
  );
  compareBudget(
    routeFailures,
    "html_bytes",
    resources.html_bytes,
    routeConfig.max_html_bytes,
  );
  compareBudget(
    routeFailures,
    "css_bytes",
    resources.css_bytes,
    routeConfig.max_css_bytes,
  );
  compareBudget(
    routeFailures,
    "js_bytes",
    resources.js_bytes,
    routeConfig.max_js_bytes,
  );
  compareBudget(
    routeFailures,
    "font_bytes",
    resources.font_bytes,
    routeConfig.max_font_bytes,
  );
  compareBudget(
    routeFailures,
    "image_bytes",
    resources.image_bytes,
    routeConfig.max_image_bytes,
  );
  compareBudget(
    routeFailures,
    "request_count",
    resources.request_count,
    routeConfig.max_request_count,
  );
  compareBudget(
    routeFailures,
    "websocket_total_bytes",
    resources.websocket_total_bytes,
    routeConfig.max_websocket_bytes,
  );
  compareBudget(
    routeFailures,
    "readable_content_ms",
    metrics.readable_content_ms,
    routeConfig.max_readable_content_ms,
  );
  compareBudget(
    routeFailures,
    "dom_content_loaded_ms",
    metrics.dom_content_loaded_ms,
    routeConfig.max_dom_content_loaded_ms,
  );
  compareBudget(
    routeFailures,
    "load_ms",
    metrics.load_ms,
    routeConfig.max_load_ms,
  );
  compareBudget(
    routeFailures,
    "fcp_ms",
    metrics.fcp_ms,
    routeConfig.max_fcp_ms,
  );
  compareBudget(routeFailures, "cls", metrics.cls, routeConfig.max_cls);
}

function compareBudget(routeFailures, metric, observed, allowed) {
  if (allowed === undefined || allowed === null || observed === null) {
    return;
  }

  if (!Number.isFinite(observed)) {
    return;
  }

  if (observed > allowed) {
    routeFailures.push({
      code: "budget_exceeded",
      metric,
      problem: `${metric} exceeded browser performance budget`,
      observed,
      allowed,
    });
  }
}

function thresholdsFor(routeConfig) {
  return Object.fromEntries(
    Object.entries(routeConfig).filter(([key]) => key.startsWith("max_")),
  );
}

function printRouteSummary(routeResult) {
  const metrics = routeResult.metrics;
  const resources = routeResult.resources;
  const line = [
    `performance browser route=${routeResult.path}`,
    `status=${routeResult.status}`,
    `http=${routeResult.http_status}`,
    `readable=${metrics.readable_content_ms ?? "missing"}ms`,
    `dcl=${metrics.dom_content_loaded_ms ?? "missing"}ms`,
    `load=${metrics.load_ms ?? "missing"}ms`,
    `fcp=${metrics.fcp_ms ?? "missing"}ms`,
    `bytes=${resources.total_bytes}`,
    `ws=${resources.websocket_total_bytes}`,
    `requests=${resources.request_count}`,
  ].join(" ");

  printHuman(line);
}

function printFailureSummary(result) {
  printHuman("performance browser failed");

  for (const failure of result.failures) {
    printHuman("");
    printHuman(`Route/page: ${failure.route}`);
    printHuman(`Problem: ${failure.problem}`);
    printHuman(`Observed: ${formatValue(failure.observed)}`);
    printHuman(`Allowed: ${formatValue(failure.allowed)}`);
    printHuman(
      "Artifact: .tmp/ci-artifacts/prod-build/browser-performance-last-run.json",
    );
    printHuman(`Next: ${nextStepFor(failure)}`);
  }
}

function nextStepFor(failure) {
  switch (failure.code) {
    case "budget_exceeded":
      return "reduce shipped assets, improve render timing, or submit an explicit route-contract budget change";
    case "missing_metric":
      return "fix browser metric collection or the page render path; do not coerce missing metrics to zero";
    case "console_errors":
    case "page_errors":
      return "fix the browser-side error before treating the page as performant";
    case "failed_resource_status":
    case "request_failures":
      return "fix failed assets/resources or remove them from the first-load path";
    default:
      return "fix the route/page behavior, then rerun ./run ci:performance-browser";
  }
}

function formatValue(value) {
  if (typeof value === "string") {
    return value;
  }

  return JSON.stringify(value);
}

async function writeResult(targetPath, result) {
  const json = `${JSON.stringify(result, null, 2)}\n`;

  if (targetPath === "-") {
    await new Promise((resolve, reject) => {
      process.stdout.write(json, (error) => {
        if (error) {
          reject(error);
          return;
        }

        resolve();
      });
    });
    return;
  }

  const resolvedPath = resolveRepoPath(targetPath);
  await fs.mkdir(path.dirname(resolvedPath), { recursive: true });
  await fs.writeFile(resolvedPath, json);
}

async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, "utf8"));
}

function printHuman(message) {
  if (outputPath === "-") {
    console.error(message);
    return;
  }

  console.log(message);
}

function resourceCategory(resourceType, contentType, resourceUrl) {
  const pathname = new URL(resourceUrl).pathname;

  if (resourceType === "document" || contentType.includes("text/html")) {
    return "html";
  }

  if (resourceType === "stylesheet" || contentType.includes("text/css")) {
    return "css";
  }

  if (resourceType === "script" || contentType.includes("javascript")) {
    return "js";
  }

  if (resourceType === "font" || pathname.match(/\.(woff2?|ttf|otf)$/)) {
    return "font";
  }

  if (resourceType === "image" || contentType.startsWith("image/")) {
    return "image";
  }

  return "other";
}

function externalHttpRequest(requestUrl, origin) {
  try {
    const parsedUrl = new URL(requestUrl);
    return (
      ["http:", "https:"].includes(parsedUrl.protocol) &&
      parsedUrl.origin !== origin
    );
  } catch (_error) {
    return false;
  }
}

function sameOriginHttpRequest(requestUrl, origin) {
  try {
    const parsedUrl = new URL(requestUrl);
    return (
      ["http:", "https:"].includes(parsedUrl.protocol) &&
      parsedUrl.origin === origin
    );
  } catch (_error) {
    return false;
  }
}

function normalizePerformanceContract(routeContract) {
  const performance = routeContract.performance ?? {};
  const routes = (routeContract.routes ?? [])
    .filter((route) => route.performance?.enabled !== false)
    .map((route) => ({
      ...route,
      ...(route.performance ?? {}),
      performance: undefined,
    }));

  return {
    schema_version: routeContract.schema_version,
    profile: performance.profile ?? {},
    required_metrics: performance.required_metrics ?? [],
    defaults: performance.defaults ?? {},
    routes,
    exceptions: performance.exceptions ?? [],
  };
}

function validateBudget(budgetConfig, budgetFailures) {
  const today = new Date();

  if (
    !Array.isArray(budgetConfig.required_metrics) ||
    budgetConfig.required_metrics.length === 0
  ) {
    budgetFailures.push({
      route: "budget",
      code: "invalid_budget",
      problem: "Browser performance budget has no required metrics",
      observed: budgetConfig.required_metrics,
      allowed: "non-empty required_metrics array",
    });
  }

  if (!Array.isArray(budgetConfig.routes) || budgetConfig.routes.length === 0) {
    budgetFailures.push({
      route: "budget",
      code: "invalid_budget",
      problem: "Browser performance budget has no routes",
      observed: budgetConfig.routes,
      allowed: "non-empty routes array",
    });
    return;
  }

  for (const routeConfig of budgetConfig.routes) {
    if (typeof routeConfig.path !== "string" || routeConfig.path.length === 0) {
      budgetFailures.push({
        route: routeConfig.label ?? "budget",
        code: "invalid_budget",
        problem: "Browser performance budget route is missing a path",
        observed: routeConfig.path,
        allowed: "non-empty route path",
      });
    }
  }

  for (const exception of budgetConfig.exceptions ?? []) {
    if (!exception.expires) {
      continue;
    }

    if (new Date(`${exception.expires}T23:59:59Z`) < today) {
      budgetFailures.push({
        route: exception.route ?? exception.path ?? "unknown",
        code: "expired_budget_exception",
        problem: "Browser performance budget exception expired",
        observed: exception.expires,
        allowed: "non-expired exception",
      });
    }
  }
}

function optionValue(argumentList, optionName, defaultValue) {
  const index = argumentList.indexOf(optionName);

  if (index === -1) {
    return defaultValue;
  }

  return argumentList[index + 1] ?? defaultValue;
}

function resolveRepoPath(filePath) {
  if (path.isAbsolute(filePath)) {
    return filePath;
  }

  return path.join(repoRoot, filePath);
}

function normalizeBaseUrl(rawBaseUrl) {
  return rawBaseUrl.replace(/\/+$/, "");
}

function currentAppSha() {
  return process.env.GITHUB_SHA ?? null;
}
