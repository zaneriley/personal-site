import { FailureCode, makeFailure } from "./failure-catalog.mjs";

export function buildPreviewCheckPlan(rawConfig, options) {
  const browserConnectUrl = options.browserConnectUrl.replace(/\/+$/, "");
  const previewFetchOrigin = new URL(browserConnectUrl).origin;
  const browserDefaults = rawConfig.browser_defaults ?? {};
  const textPolicy = {
    forbiddenText: arrayOrEmpty(rawConfig.forbidden_text),
    wrongHostText: arrayOrEmpty(rawConfig.wrong_host_text),
  };
  const viewports = arrayOrEmpty(rawConfig.viewports).map(normalizeViewport);
  const routes = arrayOrEmpty(rawConfig.routes).map((route) =>
    normalizeRoute(route, {
      browserConnectUrl,
      browserDefaults,
    }),
  );
  const plan = {
    schemaVersion: 1,
    command: "preview_browser_check",
    browserConnectUrl,
    expectedSiteOrigin: new URL(options.expectedSiteOrigin).origin,
    previewFetchOrigin,
    allowedResponseOrigins: [previewFetchOrigin],
    routeAssertions: options.routeAssertions,
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
  const mergedRoute = {
    ...options.browserDefaults,
    ...route,
  };
  const label = mergedRoute.label ?? mergedRoute.path ?? "route";

  return {
    ...mergedRoute,
    label,
    browserCheck: mergedRoute.browser_check !== false,
    allowedStatuses: arrayOrEmpty(mergedRoute.allowed_statuses),
    requiredDom: arrayOrEmpty(mergedRoute.required_dom),
    requiredVisibleText: arrayOrEmpty(
      mergedRoute.required_visible_text ?? mergedRoute.required_text,
    ),
    requireShareMetadata: mergedRoute.require_share_metadata !== false,
    routeUrl:
      typeof mergedRoute.path === "string"
        ? new URL(mergedRoute.path, `${options.browserConnectUrl}/`).toString()
        : null,
  };
}

function validatePlan(rawConfig, plan) {
  const failures = [];

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

    if (!route.browserCheck) {
      continue;
    }

    if (route.allowedStatuses.length === 0) {
      failures.push(
        makeFailure(route.label, "all", FailureCode.INVALID_ROUTE_ASSERTIONS, {
          problem: "browser-checked route must declare allowed_statuses",
        }),
      );
    }

    if (route.requiredVisibleText.length === 0) {
      failures.push(
        makeFailure(route.label, "all", FailureCode.INVALID_ROUTE_ASSERTIONS, {
          problem:
            "browser-checked route must declare required_text or required_visible_text",
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
