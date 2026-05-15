#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium, devices } from "playwright";

const scriptPath = fileURLToPath(import.meta.url);
const repoRoot = path.resolve(path.dirname(scriptPath), "../..");
const args = process.argv.slice(2);

const browserConnectUrl = normalizeBaseUrl(
  requiredOption(args, "--browser-connect-url"),
);
const expectedSiteOrigin = normalizeOrigin(
  requiredOption(args, "--expected-site-origin"),
);
const routesJsonPath = resolveRepoPath(
  requiredOption(args, "--routes-json"),
);
const screenshotsDir = resolveRepoPath(
  optionValue(args, "--screenshots-dir", ".tmp/preview-browser-screenshots"),
);
const outputPath = resolveRepoPath(
  optionValue(args, "--output", ".tmp/preview-browser-check.json"),
);
const failureSummaryPath = optionValue(args, "--failure-summary", null);
const browserConnectOrigin = new URL(browserConnectUrl).origin;
const routeConfig = await readJson(routesJsonPath);
const failures = [];
const routes = {};

validateRouteConfig(routeConfig, failures);
await fs.mkdir(screenshotsDir, { recursive: true });

const browser = await chromium.launch({ headless: true });

try {
  for (const route of routeConfig.routes ?? []) {
    if (route.browser_check === false) {
      continue;
    }

    const routeResult = await checkRoute(browser, route);
    routes[route.label ?? route.path] = routeResult;
    failures.push(...routeResult.failures);
    printRouteSummary(routeResult);
  }
} finally {
  await browser.close();
}

const result = {
  schema_version: 1,
  command: "preview_browser_check",
  generated_at: new Date().toISOString(),
  status: failures.length === 0 ? "pass" : "fail",
  browser_connect_url: browserConnectUrl,
  expected_site_origin: expectedSiteOrigin,
  allowed_response_origins: [browserConnectOrigin],
  route_assertions: path.relative(repoRoot, routesJsonPath),
  routes,
  failures,
};

await writeResult(outputPath, result);

if (failureSummaryPath !== null) {
  await writeFailureSummary(resolveRepoPath(failureSummaryPath), result);
}

if (failures.length > 0) {
  printFailureSummary(result);
  process.exit(1);
}

printHuman("preview browser check passed");

async function checkRoute(browserInstance, route) {
  const mergedRoute = {
    ...(routeConfig.browser_defaults ?? {}),
    ...route,
  };
  const label = mergedRoute.label ?? mergedRoute.path;
  const routeUrl = new URL(mergedRoute.path, `${browserConnectUrl}/`).toString();
  const viewportResults = {};
  const routeFailures = [];

  for (const viewport of routeConfig.viewports ?? []) {
    const viewportResult = await checkViewport(
      browserInstance,
      mergedRoute,
      routeUrl,
      viewport,
    );
    viewportResults[viewport.label] = viewportResult;
    routeFailures.push(...viewportResult.failures);
  }

  return {
    label,
    path: mergedRoute.path,
    result: routeFailures.length === 0 ? "pass" : "fail",
    failures: routeFailures,
    viewports: viewportResults,
  };
}

async function checkViewport(browserInstance, route, routeUrl, viewport) {
  const label = route.label ?? route.path;
  const viewportLabel = viewport.label ?? viewport.device ?? "viewport";
  const pageErrors = [];
  const consoleErrors = [];
  const requestFailures = [];
  const wrongOriginResponses = [];
  const badResponseStatuses = [];
  const failuresForViewport = [];
  const context = await browserInstance.newContext({
    ...contextOptions(viewport),
    serviceWorkers: "block",
  });

  await context.addInitScript(() => {
    window.__previewCspViolations = [];
    document.addEventListener("securitypolicyviolation", (event) => {
      window.__previewCspViolations.push({
        blocked_uri: event.blockedURI,
        violated_directive: event.violatedDirective,
        effective_directive: event.effectiveDirective,
        source_file: event.sourceFile,
        line_number: event.lineNumber,
      });
    });
  });

  const page = await context.newPage();
  page.on("pageerror", (error) => {
    pageErrors.push(error.message);
  });
  page.on("console", (message) => {
    if (message.type() === "error") {
      consoleErrors.push(message.text());
    }
  });
  page.on("requestfailed", (request) => {
    requestFailures.push({
      url: request.url(),
      resource_type: request.resourceType(),
      failure: request.failure()?.errorText ?? "unknown",
    });
  });
  page.on("response", (response) => {
    const responseUrl = response.url();
    const parsedUrl = parseHttpUrl(responseUrl);

    if (parsedUrl !== null && parsedUrl.origin !== browserConnectOrigin) {
      wrongOriginResponses.push({
        url: responseUrl,
        origin: parsedUrl.origin,
        allowed_origins: [browserConnectOrigin],
      });
    }

    if (parsedUrl !== null && response.status() >= 400) {
      badResponseStatuses.push({
        url: responseUrl,
        status: response.status(),
      });
    }
  });

  let mainResponse = null;
  let screenshotPath = null;
  let bodyText = "";
  let html = "";
  let cspViolations = [];

  try {
    mainResponse = await page.goto(routeUrl, {
      waitUntil: "domcontentloaded",
      timeout: 20_000,
    });

    await page.waitForLoadState("load", { timeout: 10_000 }).catch(() => {});

    for (const selector of route.required_dom ?? []) {
      await page.locator(selector).first().waitFor({
        state: "visible",
        timeout: 5_000,
      });
    }

    for (const text of route.required_visible_text ?? route.required_text ?? []) {
      await page.getByText(text, { exact: false }).first().waitFor({
        state: "visible",
        timeout: 5_000,
      });
    }

    await page.waitForTimeout(250);
    bodyText = await page.locator("body").innerText({ timeout: 5_000 });
    html = await page.content();
    cspViolations = await page.evaluate(
      () => window.__previewCspViolations ?? [],
    );

  } catch (error) {
    failuresForViewport.push(
      failure(label, viewportLabel, "browser_check_exception", {
        message: error.message,
      }),
    );
  }

  if (route.screenshot !== false) {
    screenshotPath = path.join(
      screenshotsDir,
      `${safeFilename(label)}-${safeFilename(viewportLabel)}.png`,
    );

    await page
      .screenshot({ path: screenshotPath, fullPage: true })
      .catch((error) => {
        failuresForViewport.push(
          failure(label, viewportLabel, "screenshot_failed", {
            message: error.message,
          }),
        );
      });
  }

  const status = mainResponse?.status() ?? null;
  const statusAllowed =
    status !== null && (route.allowed_statuses ?? []).includes(status);

  if (!statusAllowed) {
    failuresForViewport.push(
      failure(label, viewportLabel, "bad_document_status", {
        status,
        allowed_statuses: route.allowed_statuses ?? [],
      }),
    );
  }

  failuresForViewport.push(
    ...missingVisibleTextFailures(label, viewportLabel, route, bodyText),
    ...forbiddenVisibleTextFailures(label, viewportLabel, bodyText),
    ...wrongHostTextFailures(label, viewportLabel, html),
    ...domAbsoluteUrlFailures(label, viewportLabel, await domAbsoluteUrls(page)),
    ...shareMetadataFailures(label, viewportLabel, route, await shareMetadata(page)),
    ...pageErrors.map((message) =>
      failure(label, viewportLabel, "page_error", { message }),
    ),
    ...consoleErrors.map((message) =>
      failure(label, viewportLabel, "console_error", { message }),
    ),
    ...requestFailures.map((requestFailure) =>
      failure(label, viewportLabel, "request_failed", requestFailure),
    ),
    ...wrongOriginResponses.map((response) =>
      failure(label, viewportLabel, "wrong_origin_response", response),
    ),
    ...badResponseStatuses.map((response) =>
      failure(label, viewportLabel, "bad_response_status", response),
    ),
    ...cspViolations.map((violation) =>
      failure(label, viewportLabel, "csp_violation", violation),
    ),
  );

  await context.close();

  return {
    label: viewportLabel,
    result: failuresForViewport.length === 0 ? "pass" : "fail",
    status,
    screenshot: screenshotPath,
    failures: failuresForViewport,
    page_errors: pageErrors,
    console_errors: consoleErrors,
    request_failures: requestFailures,
    wrong_origin_responses: wrongOriginResponses,
    bad_response_statuses: badResponseStatuses,
    csp_violations: cspViolations,
  };
}

function missingVisibleTextFailures(label, viewportLabel, route, bodyText) {
  return (route.required_visible_text ?? route.required_text ?? [])
    .filter((text) => !bodyText.includes(text))
    .map((text) =>
      failure(label, viewportLabel, "missing_visible_text", { text }),
    );
}

function forbiddenVisibleTextFailures(label, viewportLabel, bodyText) {
  return (routeConfig.forbidden_text ?? [])
    .filter((text) => bodyText.includes(text))
    .map((text) =>
      failure(label, viewportLabel, "forbidden_visible_text", { text }),
    );
}

function wrongHostTextFailures(label, viewportLabel, html) {
  return (routeConfig.wrong_host_text ?? [])
    .filter((text) => html.includes(text))
    .map((text) => failure(label, viewportLabel, "wrong_host_text", { text }));
}

async function domAbsoluteUrls(page) {
  return page.evaluate(() => {
    const checks = [
      { name: "canonical", selector: 'link[rel="canonical"]', attr: "href" },
      { name: "og:url", selector: 'meta[property="og:url"]', attr: "content" },
      {
        name: "og:image",
        selector: 'meta[property="og:image"]',
        attr: "content",
      },
      {
        name: "twitter:image",
        selector: 'meta[name="twitter:image"]',
        attr: "content",
      },
    ];

    return checks.flatMap((check) =>
      Array.from(document.querySelectorAll(check.selector)).map((element) => ({
        ...check,
        value: element.getAttribute(check.attr),
      })),
    );
  });
}

function domAbsoluteUrlFailures(label, viewportLabel, urls) {
  return urls.flatMap((entry) => {
    if (entry.value === null || entry.value.trim() === "") {
      return [
        failure(label, viewportLabel, "wrong_site_origin_in_dom", {
          name: entry.name,
          selector: entry.selector,
          issue: "empty_value",
          value: entry.value,
        }),
      ];
    }

    if (!/^https?:\/\//i.test(entry.value)) {
      return [
        failure(label, viewportLabel, "wrong_site_origin_in_dom", {
          name: entry.name,
          selector: entry.selector,
          issue: "non_absolute_value",
          value: entry.value,
        }),
      ];
    }

    try {
      const parsedUrl = new URL(entry.value);

      if (parsedUrl.origin !== expectedSiteOrigin) {
        return [
          failure(label, viewportLabel, "wrong_site_origin_in_dom", {
            name: entry.name,
            selector: entry.selector,
            issue: "origin_mismatch",
            value: entry.value,
            origin: parsedUrl.origin,
            expected_origin: expectedSiteOrigin,
          }),
        ];
      }
    } catch (error) {
      return [
        failure(label, viewportLabel, "wrong_site_origin_in_dom", {
          name: entry.name,
          selector: entry.selector,
          issue: "unparseable",
          value: entry.value,
          message: error.message,
        }),
      ];
    }

    return [];
  });
}

async function shareMetadata(page) {
  return page.evaluate(() => ({
    og_title: document
      .querySelector('meta[property="og:title"]')
      ?.getAttribute("content"),
    og_description: document
      .querySelector('meta[property="og:description"]')
      ?.getAttribute("content"),
    og_url: document
      .querySelector('meta[property="og:url"]')
      ?.getAttribute("content"),
    og_image: document
      .querySelector('meta[property="og:image"]')
      ?.getAttribute("content"),
    twitter_card: document
      .querySelector('meta[name="twitter:card"]')
      ?.getAttribute("content"),
    twitter_title: document
      .querySelector('meta[name="twitter:title"]')
      ?.getAttribute("content"),
    twitter_description: document
      .querySelector('meta[name="twitter:description"]')
      ?.getAttribute("content"),
    twitter_image: document
      .querySelector('meta[name="twitter:image"]')
      ?.getAttribute("content"),
    robots: document
      .querySelector('meta[name="robots"]')
      ?.getAttribute("content"),
  }));
}

function shareMetadataFailures(label, viewportLabel, route, metadata) {
  if (route.require_share_metadata === false) {
    return [];
  }

  return Object.entries({
    "og:title": metadata.og_title,
    "og:description": metadata.og_description,
    "og:url": metadata.og_url,
    "og:image": metadata.og_image,
    "twitter:card": metadata.twitter_card,
    "twitter:title": metadata.twitter_title,
    "twitter:description": metadata.twitter_description,
    "twitter:image": metadata.twitter_image,
  })
    .filter(([, value]) => value === undefined || value.trim() === "")
    .map(([name]) =>
      failure(label, viewportLabel, "missing_share_metadata", { name }),
    );
}

function contextOptions(viewport) {
  if (viewport.device !== undefined) {
    const device = devices[viewport.device];

    if (device === undefined) {
      throw new Error(`unknown Playwright device: ${viewport.device}`);
    }

    return device;
  }

  return {
    viewport: {
      width: viewport.width,
      height: viewport.height,
    },
  };
}

function validateRouteConfig(config, validationFailures) {
  if (config.schema_version !== 1) {
    validationFailures.push(
      failure("schema", "all", "invalid_schema_version", {
        expected: 1,
        observed: config.schema_version,
      }),
    );
  }

  for (const viewport of config.viewports ?? []) {
    if (typeof viewport.label !== "string" || viewport.label.length === 0) {
      validationFailures.push(
        failure("schema", "all", "invalid_viewport", { viewport }),
      );
    }
  }

  for (const route of config.routes ?? []) {
    if (typeof route.path !== "string" || !route.path.startsWith("/")) {
      validationFailures.push(
        failure(route.label ?? "schema", "all", "invalid_route_path", {
          path: route.path,
        }),
      );
    }
  }
}

function failure(route, viewport, code, detail) {
  return {
    route,
    viewport,
    code,
    ...detail,
  };
}

function parseHttpUrl(rawUrl) {
  try {
    const parsedUrl = new URL(rawUrl);

    if (["http:", "https:"].includes(parsedUrl.protocol)) {
      return parsedUrl;
    }
  } catch {
    return null;
  }

  return null;
}

async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, "utf8"));
}

async function writeResult(filePath, result) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(`${filePath}.tmp`, `${JSON.stringify(result, null, 2)}\n`);
  await fs.rename(`${filePath}.tmp`, filePath);
}

async function writeFailureSummary(filePath, result) {
  const lines = [
    `# preview_browser_check: ${result.status}`,
    "",
    `browser_connect_url: ${result.browser_connect_url}`,
    `expected_site_origin: ${result.expected_site_origin}`,
    "",
  ];

  if (result.failures.length === 0) {
    lines.push("No failures.");
  } else {
    lines.push("## Failures", "");
    for (const checkFailure of result.failures) {
      lines.push(
        `- ${checkFailure.route} [${checkFailure.viewport}] ${checkFailure.code}: ${JSON.stringify(checkFailure)}`,
      );
    }
  }

  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, `${lines.join("\n")}\n`);
}

function printRouteSummary(routeResult) {
  const icon = routeResult.result === "pass" ? "PASS" : "FAIL";
  printHuman(`${icon} ${routeResult.label} ${routeResult.path}`);
}

function printFailureSummary(result) {
  printHuman("preview browser check failed");

  for (const checkFailure of result.failures) {
    printHuman(
      `  ${checkFailure.route} [${checkFailure.viewport}] ${checkFailure.code}`,
    );
  }
}

function printHuman(message) {
  console.error(message);
}

function optionValue(argumentList, optionName, defaultValue) {
  const index = argumentList.indexOf(optionName);

  if (index === -1) {
    return defaultValue;
  }

  return argumentList[index + 1] ?? defaultValue;
}

function requiredOption(argumentList, optionName) {
  const value = optionValue(argumentList, optionName, null);

  if (value === null || value.trim() === "") {
    throw new Error(`${optionName} is required`);
  }

  return value;
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

function normalizeOrigin(rawOrigin) {
  return new URL(rawOrigin).origin;
}

function safeFilename(value) {
  return value.replaceAll(/[^a-zA-Z0-9_-]/g, "-").replaceAll(/-+/g, "-");
}
