import { FailureCode, makeFailure } from "./failure-catalog.mjs";

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
    ...missingRequiredContentFailures(route, viewportLabel, observation.bodyText),
    ...visibleErrorStateFailures(route, viewportLabel, observation.bodyText, textPolicy),
    ...internalHostLeakFailures(route, viewportLabel, observation.html, textPolicy),
    ...canonicalSiteOriginFailures(
      route,
      viewportLabel,
      observation.documentAbsoluteUrls,
      expectedSiteOrigin,
    ),
    ...shareMetadataFailures(route, viewportLabel, observation.documentMetadata),
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
  return textPolicy.forbiddenText
    .filter((text) => bodyText.includes(text))
    .map((text) =>
      makeFailure(route.label, viewportLabel, FailureCode.FORBIDDEN_VISIBLE_TEXT, {
        text,
      }),
    );
}

function internalHostLeakFailures(route, viewportLabel, html, textPolicy) {
  return textPolicy.wrongHostText
    .filter((text) => html.includes(text))
    .map((text) =>
      makeFailure(route.label, viewportLabel, FailureCode.WRONG_HOST_TEXT, {
        text,
      }),
    );
}

function canonicalSiteOriginFailures(route, viewportLabel, urls, expectedSiteOrigin) {
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

  return Object.entries(metadata)
    .filter(([, value]) => value === undefined || value.trim() === "")
    .map(([name]) =>
      makeFailure(route.label, viewportLabel, FailureCode.MISSING_SHARE_METADATA, {
        name,
      }),
    );
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
    ...observation.unexpectedNetworkResponses.map((response) =>
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
