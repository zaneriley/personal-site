import { FailureCode, makeFailure } from "./failure-catalog.mjs";

const REQUIRED_SHARE_METADATA = [
  "og:title",
  "og:description",
  "og:url",
  "og:image",
  "twitter:card",
  "twitter:title",
  "twitter:description",
  "twitter:image",
];

export function assertViewport({
  route,
  viewportLabel,
  observation,
  expectedSiteOrigin,
  textPolicy,
}) {
  const failures = [...observation.exerciseFailures];

  failures.push(
    ...documentStatusFailures(route, viewportLabel, observation.status),
    ...missingRequiredDomFailures(route, viewportLabel, observation.requiredDomState),
    ...missingRequiredContentFailures(route, viewportLabel, observation.bodyText),
    ...visibleErrorStateFailures(route, viewportLabel, observation.bodyText, textPolicy),
    ...htmlPolicyFailures(route, viewportLabel, observation.html, textPolicy),
    ...documentPublicUrlOriginFailures(
      route,
      viewportLabel,
      observation.documentAbsoluteUrls,
      expectedSiteOrigin,
    ),
    ...shareMetadataFailures(route, viewportLabel, observation.documentMetadata),
    ...liveViewFailures(route, viewportLabel, observation.clientState),
    ...viewportLayoutFailures(route, viewportLabel, observation.layoutState),
    ...runtimeObservationFailures(route, viewportLabel, observation),
  );

  return failures;
}

function documentStatusFailures(route, viewportLabel, status) {
  if (status !== null && route.allowedStatuses.includes(status)) {
    return [];
  }

  return [
    makeFailure(route.label, viewportLabel, FailureCode.BAD_DOCUMENT_STATUS, {
      status,
      allowed_statuses: route.allowedStatuses,
    }),
  ];
}

function missingRequiredDomFailures(route, viewportLabel, requiredDomState) {
  return requiredDomState
    .filter((entry) => !entry.visible)
    .map((entry) =>
      makeFailure(route.label, viewportLabel, FailureCode.MISSING_REQUIRED_DOM, {
        selector: entry.selector,
        reason: entry.reason,
      }),
    );
}

function missingRequiredContentFailures(route, viewportLabel, bodyText) {
  return route.requiredVisibleText
    .filter((text) => !bodyText.includes(text))
    .map((text) =>
      makeFailure(route.label, viewportLabel, FailureCode.MISSING_VISIBLE_TEXT, {
        text,
      }),
    );
}

function visibleErrorStateFailures(route, viewportLabel, bodyText, textPolicy) {
  return textPolicy.forbiddenVisibleText
    .filter((text) => bodyText.includes(text))
    .map((text) =>
      makeFailure(route.label, viewportLabel, FailureCode.FORBIDDEN_VISIBLE_TEXT, {
        text,
      }),
    );
}

function htmlPolicyFailures(route, viewportLabel, html, textPolicy) {
  return textPolicy.forbiddenHtmlText
    .filter((text) => html.includes(text))
    .map((text) =>
      makeFailure(route.label, viewportLabel, FailureCode.FORBIDDEN_HTML_TEXT, {
        text,
      }),
    );
}

function documentPublicUrlOriginFailures(
  route,
  viewportLabel,
  urls,
  expectedSiteOrigin,
) {
  return urls.flatMap((entry) => {
    if (entry.value === null || entry.value.trim() === "") {
      return [
        makeFailure(
          route.label,
          viewportLabel,
          FailureCode.WRONG_SITE_ORIGIN_IN_DOM,
          {
            name: entry.name,
            selector: entry.selector,
            issue: "empty_value",
            value: entry.value,
          },
        ),
      ];
    }

    if (!/^https?:\/\//i.test(entry.value)) {
      return [
        makeFailure(
          route.label,
          viewportLabel,
          FailureCode.WRONG_SITE_ORIGIN_IN_DOM,
          {
            name: entry.name,
            selector: entry.selector,
            issue: "non_absolute_value",
            value: entry.value,
          },
        ),
      ];
    }

    try {
      const parsedUrl = new URL(entry.value);

      if (parsedUrl.origin !== expectedSiteOrigin) {
        return [
          makeFailure(
            route.label,
            viewportLabel,
            FailureCode.WRONG_SITE_ORIGIN_IN_DOM,
            {
              name: entry.name,
              selector: entry.selector,
              issue: "origin_mismatch",
              value: entry.value,
              origin: parsedUrl.origin,
              expected_origin: expectedSiteOrigin,
            },
          ),
        ];
      }
    } catch (error) {
      return [
        makeFailure(
          route.label,
          viewportLabel,
          FailureCode.WRONG_SITE_ORIGIN_IN_DOM,
          {
            name: entry.name,
            selector: entry.selector,
            issue: "unparseable",
            value: entry.value,
            message: error.message,
          },
        ),
      ];
    }

    return [];
  });
}

function shareMetadataFailures(route, viewportLabel, metadata) {
  if (!route.requireShareMetadata) {
    return [];
  }

  return REQUIRED_SHARE_METADATA
    .filter((name) => {
      const value = metadata[name];

      return value === undefined || value.trim() === "";
    })
    .map((name) =>
      makeFailure(route.label, viewportLabel, FailureCode.MISSING_SHARE_METADATA, {
        name,
      }),
    );
}

function liveViewFailures(route, viewportLabel, clientState) {
  if (!route.requireLiveView || clientState.liveViewConnected) {
    return [];
  }

  return [
    makeFailure(route.label, viewportLabel, FailureCode.LIVE_VIEW_NOT_CONNECTED, {
      app_js_loaded: clientState.appJsLoaded,
      live_socket_present: clientState.liveSocketPresent,
    }),
  ];
}

function viewportLayoutFailures(route, viewportLabel, layoutState) {
  const failures = [];

  if (layoutState.bodyTextLength === 0) {
    failures.push(
      makeFailure(route.label, viewportLabel, FailureCode.BLANK_PAGE, {
        problem: "document body has no visible text",
      }),
    );
  }

  if (layoutState.documentScrollWidth > layoutState.viewportWidth + 2) {
    failures.push(
      makeFailure(route.label, viewportLabel, FailureCode.VIEWPORT_OVERFLOW, {
        viewport_width: layoutState.viewportWidth,
        document_scroll_width: layoutState.documentScrollWidth,
      }),
    );
  }

  return failures;
}

function runtimeObservationFailures(route, viewportLabel, observation) {
  return [
    ...observation.pageErrors.map((message) =>
      makeFailure(route.label, viewportLabel, FailureCode.PAGE_ERROR, { message }),
    ),
    ...observation.consoleErrors.map((message) =>
      makeFailure(route.label, viewportLabel, FailureCode.CONSOLE_ERROR, {
        message,
      }),
    ),
    ...observation.requestFailures.map((requestFailure) =>
      makeFailure(route.label, viewportLabel, FailureCode.REQUEST_FAILED, {
        ...requestFailure,
      }),
    ),
    ...observation.wrongOriginResponses.map((response) =>
      makeFailure(route.label, viewportLabel, FailureCode.WRONG_ORIGIN_RESPONSE, {
        ...response,
      }),
    ),
    ...observation.badResponseStatuses.map((response) =>
      makeFailure(route.label, viewportLabel, FailureCode.BAD_RESPONSE_STATUS, {
        ...response,
      }),
    ),
    ...observation.cspViolations.map((violation) =>
      makeFailure(route.label, viewportLabel, FailureCode.CSP_VIOLATION, {
        ...violation,
      }),
    ),
  ];
}
