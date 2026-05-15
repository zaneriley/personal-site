#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";
import { observeRouteViewport } from "./preview-page-acceptance/browser-observer.mjs";
import { buildPreviewCheckPlan } from "./preview-page-acceptance/check-plan.mjs";
import { assertViewport } from "./preview-page-acceptance/preview-assertions.mjs";
import {
  buildResult,
  printFailureSummary,
  printRouteSummary,
  printStatusLine,
  writeFailureSummary,
  writeResult,
} from "./preview-page-acceptance/reporting.mjs";

const scriptPath = fileURLToPath(import.meta.url);
const repoRoot =
  process.env.PREVIEW_PAGE_ACCEPTANCE_ROOT ??
  path.resolve(path.dirname(scriptPath), "../..");

const exitStatus = await main(process.argv.slice(2));
process.exit(exitStatus);

async function main(args) {
  const options = parseOptions(args);
  const rawConfig = await readJson(options.routesContractPath);
  const { plan, failures: planFailures } = buildPreviewCheckPlan(rawConfig, {
    browserConnectUrl: options.browserConnectUrl,
    expectedSiteOrigin: options.expectedSiteOrigin,
    routeConfigFile: path.relative(repoRoot, options.routesContractPath),
  });

  await fs.mkdir(options.screenshotsDir, { recursive: true });

  const result =
    planFailures.length > 0
      ? buildResult({ plan, routes: {}, failures: planFailures })
      : await runPreviewBrowserCheck(plan, options);

  await writeResult(options.outputPath, result);

  if (options.failureSummaryPath !== null) {
    await writeFailureSummary(options.failureSummaryPath, result);
  }

  if (result.failures.length > 0) {
    printFailureSummary(result);
    return 1;
  }

  printStatusLine("preview page acceptance passed");
  return 0;
}

async function runPreviewBrowserCheck(plan, options) {
  const browser = await chromium.launch({ headless: true });
  const routes = {};
  const failures = [];

  try {
    for (const route of plan.routes) {
      if (!route.browserCheck) {
        continue;
      }

      const routeResult = await checkRoute(browser, route, plan, options);
      routes[route.label] = routeResult;
      failures.push(...routeResult.failures);
      printRouteSummary(routeResult);
    }
  } finally {
    await browser.close();
  }

  return buildResult({ plan, routes, failures });
}

async function checkRoute(browser, route, plan, options) {
  const viewportResults = {};
  const routeFailures = [];

  for (const viewport of plan.viewports) {
    const observation = await observeRouteViewport({
      browser,
      route,
      viewport,
      previewFetchOrigin: plan.previewFetchOrigin,
      screenshotsDir: options.screenshotsDir,
    });
    const viewportFailures = assertViewport({
      route,
      viewportLabel: viewport.label,
      observation,
      expectedSiteOrigin: plan.expectedSiteOrigin,
      textPolicy: plan.textPolicy,
    });

    viewportResults[viewport.label] = {
      label: viewport.label,
      result: viewportFailures.length === 0 ? "pass" : "fail",
      status: observation.status,
      screenshot: observation.screenshot,
      failures: viewportFailures,
      page_errors: observation.pageErrors,
      console_errors: observation.consoleErrors,
      request_failures: observation.requestFailures,
      wrong_origin_responses: observation.wrongOriginResponses,
      bad_response_statuses: observation.badResponseStatuses,
      csp_violations: observation.cspViolations,
      required_dom_state: observation.requiredDomState,
      client_state: observation.clientState,
      layout_state: observation.layoutState,
    };
    routeFailures.push(...viewportFailures);
  }

  return {
    label: route.label,
    path: route.path,
    result: routeFailures.length === 0 ? "pass" : "fail",
    failures: routeFailures,
    viewports: viewportResults,
  };
}

function parseOptions(args) {
  const browserConnectUrl = normalizeBaseUrl(
    requiredOption(args, "--browser-connect-url"),
  );

  return {
    browserConnectUrl,
    expectedSiteOrigin: normalizeOrigin(
      requiredOption(args, "--expected-site-origin"),
    ),
    routesContractPath: resolveRepoPath(requiredOption(args, "--routes-contract")),
    screenshotsDir: resolveRepoPath(
      optionValue(
        args,
        "--screenshots-dir",
        ".tmp/ci-artifacts/preview-page-acceptance/screenshots",
      ),
    ),
    outputPath: resolveRepoPath(
      optionValue(
        args,
        "--output",
        ".tmp/ci-artifacts/preview-page-acceptance/preview-page-acceptance.json",
      ),
    ),
    failureSummaryPath: resolveOptionalPath(
      optionValue(args, "--failure-summary", null),
    ),
  };
}

async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, "utf8"));
}

function optionValue(argumentList, optionName, defaultValue) {
  const index = argumentList.indexOf(optionName);

  if (index === -1) {
    return defaultValue;
  }

  const value = argumentList[index + 1];

  if (value === undefined || value.startsWith("--")) {
    throw new Error(`${optionName} requires a value`);
  }

  return value;
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

function resolveOptionalPath(filePath) {
  if (filePath === null) {
    return null;
  }

  return resolveRepoPath(filePath);
}

function normalizeBaseUrl(rawBaseUrl) {
  return rawBaseUrl.replace(/\/+$/, "");
}

function normalizeOrigin(rawOrigin) {
  return new URL(rawOrigin).origin;
}
