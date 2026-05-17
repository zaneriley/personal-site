export const FailureCode = Object.freeze({
  BAD_DOCUMENT_STATUS: "bad_document_status",
  BAD_RESPONSE_STATUS: "bad_response_status",
  BROWSER_CHECK_EXCEPTION: "browser_check_exception",
  CONSOLE_ERROR: "console_error",
  CSP_VIOLATION: "csp_violation",
  BLANK_PAGE: "blank_page",
  INVALID_ROUTE_ASSERTIONS: "invalid_route_assertions",
  INVALID_ROUTE_PATH: "invalid_route_path",
  INVALID_SCHEMA_VERSION: "invalid_schema_version",
  INVALID_BROWSER_ROUTE_SET: "invalid_browser_route_set",
  INVALID_TEXT_POLICY: "invalid_text_policy",
  INVALID_VIEWPORT: "invalid_viewport",
  LIVE_VIEW_NOT_CONNECTED: "live_view_not_connected",
  MISSING_REQUIRED_DOM: "missing_required_dom",
  MISSING_SHARE_METADATA: "missing_share_metadata",
  MISSING_VISIBLE_TEXT: "missing_visible_text",
  PAGE_ERROR: "page_error",
  REQUEST_FAILED: "request_failed",
  SCREENSHOT_FAILED: "screenshot_failed",
  VIEWPORT_OVERFLOW: "viewport_overflow",
  FORBIDDEN_VISIBLE_TEXT: "forbidden_visible_text",
  FORBIDDEN_HTML_TEXT: "forbidden_html_text",
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
