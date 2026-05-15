import { devices } from "playwright";
import { FailureCode, makeFailure } from "./failure-catalog.mjs";

export function buildPreviewCheckPlan(rawConfig, options) {
  const browserConnectUrl = options.browserConnectUrl.replace(/\/+$/, "");
  const previewFetchOrigin = new URL(browserConnectUrl).origin;
  const browserDefaults = rawConfig.browser?.defaults ?? {};
  const textPolicy = {
    forbiddenVisibleText: arrayOrEmpty(rawConfig.text_policy?.forbidden_visible_text),
    forbiddenHtmlText: arrayOrEmpty(rawConfig.text_policy?.forbidden_html_text),
  };
  const viewports = arrayOrEmpty(rawConfig.browser?.viewports).map(normalizeViewport);
  const routes = arrayOrEmpty(rawConfig.routes).map((route) =>
    normalizeRoute(route, {
      browserConnectUrl,
      browserDefaults,
    }),
  );
  const plan = {
    schemaVersion: 1,
    command: "preview_page_acceptance",
    browserConnectUrl,
    expectedSiteOrigin: new URL(options.expectedSiteOrigin).origin,
    previewFetchOrigin,
    allowedResponseOrigins: [previewFetchOrigin],
    routeConfigFile: options.routeConfigFile,
    textPolicy,
    viewports,
    routes,
  };

  return { plan, failures: validatePlan(rawConfig, plan) };
}

function normalizeViewport(viewport) {
  return {
    ...viewport,
    label: viewport.label ?? viewport.device ?? "viewport",
  };
}

function normalizeRoute(route, options) {
  const browser = route.browser ?? {};
  const mergedRoute = {
    ...options.browserDefaults,
    ...route,
    ...browser,
  };
  const label = mergedRoute.label ?? mergedRoute.path ?? "route";
  const requiredBodyText = arrayOrEmpty(route.required_body_text);

  return {
    ...mergedRoute,
    label,
    browserCheck: browser.enabled !== false && mergedRoute.browser_check !== false,
    allowedStatuses: arrayOrEmpty(mergedRoute.allowed_statuses),
    requiredBodyText,
    requiredDom: arrayOrEmpty(browser.required_dom ?? mergedRoute.required_dom),
    requiredVisibleText: arrayOrEmpty(
      browser.required_visible_text ??
        mergedRoute.required_visible_text ??
        requiredBodyText,
    ),
    requireLiveView: mergedRoute.require_live_view !== false,
    requireShareMetadata: mergedRoute.require_share_metadata !== false,
    routeUrl:
      typeof mergedRoute.path === "string"
        ? new URL(mergedRoute.path, `${options.browserConnectUrl}/`).toString()
        : null,
  };
}

function validatePlan(rawConfig, plan) {
  const failures = [];
  const browserCheckedRoutes = plan.routes.filter((route) => route.browserCheck);

  if (rawConfig.schema_version !== 1) {
    failures.push(
      makeFailure("schema", "all", FailureCode.INVALID_SCHEMA_VERSION, {
        expected: 1,
        observed: rawConfig.schema_version,
      }),
    );
  }

  if (plan.viewports.length === 0) {
    failures.push(
      makeFailure("schema", "all", FailureCode.INVALID_VIEWPORT, {
        problem: "at least one viewport is required",
      }),
    );
  }

  for (const viewport of plan.viewports) {
    if (typeof viewport.label !== "string" || viewport.label.length === 0) {
      failures.push(
        makeFailure("schema", "all", FailureCode.INVALID_VIEWPORT, {
          viewport,
        }),
      );
    }

    if (viewport.device !== undefined && devices[viewport.device] === undefined) {
      failures.push(
        makeFailure("schema", "all", FailureCode.INVALID_VIEWPORT, {
          problem: `unknown Playwright device: ${viewport.device}`,
          viewport,
        }),
      );
    }

    if (
      viewport.device === undefined &&
      (!Number.isInteger(viewport.width) ||
        viewport.width <= 0 ||
        !Number.isInteger(viewport.height) ||
        viewport.height <= 0)
    ) {
      failures.push(
        makeFailure("schema", "all", FailureCode.INVALID_VIEWPORT, {
          problem: "viewport must declare a known device or positive width/height",
          viewport,
        }),
      );
    }
  }

  if (browserCheckedRoutes.length === 0) {
    failures.push(
      makeFailure("schema", "all", FailureCode.INVALID_BROWSER_ROUTE_SET, {
        problem: "at least one route must enable browser checks",
      }),
    );
  }

  if (!Array.isArray(rawConfig.text_policy?.forbidden_visible_text)) {
    failures.push(
      makeFailure("schema", "all", FailureCode.INVALID_TEXT_POLICY, {
        problem: "text_policy.forbidden_visible_text must be an array",
      }),
    );
  }

  if (!Array.isArray(rawConfig.text_policy?.forbidden_html_text)) {
    failures.push(
      makeFailure("schema", "all", FailureCode.INVALID_TEXT_POLICY, {
        problem: "text_policy.forbidden_html_text must be an array",
      }),
    );
  }

  for (const route of plan.routes) {
    if (typeof route.path !== "string" || !route.path.startsWith("/")) {
      failures.push(
        makeFailure(route.label, "all", FailureCode.INVALID_ROUTE_PATH, {
          path: route.path,
        }),
      );
      continue;
    }

    if (route.allowedStatuses.length === 0) {
      failures.push(
        makeFailure(route.label, "all", FailureCode.INVALID_ROUTE_ASSERTIONS, {
          problem: "route must declare allowed_statuses",
        }),
      );
    }

    if (route.requiredBodyText.length === 0) {
      failures.push(
        makeFailure(route.label, "all", FailureCode.INVALID_ROUTE_ASSERTIONS, {
          problem: "route must declare required_body_text for route_smoke",
        }),
      );
    }

    if (!route.browserCheck) {
      continue;
    }

    if (route.requiredVisibleText.length === 0) {
      failures.push(
        makeFailure(route.label, "all", FailureCode.INVALID_ROUTE_ASSERTIONS, {
          problem:
            "browser-checked route must declare browser.required_visible_text or required_body_text",
        }),
      );
    }

    if (route.requiredDom.length === 0 && !route.requireShareMetadata) {
      failures.push(
        makeFailure(route.label, "all", FailureCode.INVALID_ROUTE_ASSERTIONS, {
          problem:
            "browser-checked route must assert required_dom or share metadata",
        }),
      );
    }
  }

  return failures;
}

function arrayOrEmpty(value) {
  if (Array.isArray(value)) {
    return value;
  }

  return [];
}
