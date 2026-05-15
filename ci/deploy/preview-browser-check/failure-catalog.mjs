export const FailureCode = Object.freeze({
  BAD_DOCUMENT_STATUS: "bad_document_status",
  BAD_RESPONSE_STATUS: "bad_response_status",
  BROWSER_CHECK_EXCEPTION: "browser_check_exception",
  CONSOLE_ERROR: "console_error",
  CSP_VIOLATION: "csp_violation",
  INVALID_ROUTE_ASSERTIONS: "invalid_route_assertions",
  INVALID_ROUTE_PATH: "invalid_route_path",
  INVALID_SCHEMA_VERSION: "invalid_schema_version",
  INVALID_VIEWPORT: "invalid_viewport",
  MISSING_SHARE_METADATA: "missing_share_metadata",
  MISSING_VISIBLE_TEXT: "missing_visible_text",
  PAGE_ERROR: "page_error",
  REQUEST_FAILED: "request_failed",
  SCREENSHOT_FAILED: "screenshot_failed",
  FORBIDDEN_VISIBLE_TEXT: "forbidden_visible_text",
  WRONG_HOST_TEXT: "wrong_host_text",
  WRONG_ORIGIN_RESPONSE: "wrong_origin_response",
  WRONG_SITE_ORIGIN_IN_DOM: "wrong_site_origin_in_dom",
});

export function makeFailure(route, viewport, code, detail = {}) {
  return {
    route,
    viewport,
    code,
    ...detail,
  };
}
