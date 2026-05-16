import fs from "node:fs/promises";
import path from "node:path";

const failureDetailFormatters = {
  bad_document_status: (failure) =>
    `status ${failure.status}; allowed ${failure.allowed_statuses.join(", ")}`,
  csp_violation: (failure) =>
    `${failure.violated_directive}: ${sanitizeDetail(failure.blocked_uri)}`,
  live_view_not_connected: (failure) =>
    `app_js_loaded=${failure.app_js_loaded} live_socket_present=${failure.live_socket_present} live_websocket_seen=${failure.live_websocket_seen}`,
  missing_required_dom: (failure) => `${failure.selector}: ${failure.reason}`,
  missing_share_metadata: (failure) => failure.name,
  viewport_overflow: (failure) =>
    `document ${failure.document_scroll_width}px > viewport ${failure.viewport_width}px`,
  wrong_site_origin_in_dom: (failure) => {
    const expected =
      failure.expected_origin === undefined
        ? ""
        : ` expected ${redactUrl(failure.expected_origin)}`;

    return `${failure.name} ${failure.issue}: ${JSON.stringify(redactUrl(failure.value))}${expected}`;
  },
};

export function buildResult({ plan, routes, failures, routeContractSha256 }) {
  return {
    schema_version: 1,
    command: plan.command,
    generated_at: new Date().toISOString(),
    preview_deploy_attempt_id: process.env.PREVIEW_DEPLOY_ATTEMPT_ID ?? null,
    preview_page_acceptance_image_ref:
      process.env.PREVIEW_PAGE_ACCEPTANCE_IMAGE_REF ?? null,
    status: failures.length === 0 ? "pass" : "fail",
    browser_connect_url: plan.browserConnectUrl,
    expected_site_origin: plan.expectedSiteOrigin,
    allowed_response_origins: plan.allowedResponseOrigins,
    route_config_file: plan.routeConfigFile,
    route_contract_sha256: routeContractSha256,
    routes,
    failures,
    failure_summary: summarizeFailures(failures),
  };
}

export async function writeResult(filePath, result) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(`${filePath}.tmp`, `${JSON.stringify(result, null, 2)}\n`);
  await fs.rename(`${filePath}.tmp`, filePath);
}

export async function writeFailureSummary(filePath, result) {
  const lines = [
    `# preview_page_acceptance: ${result.status}`,
    "",
    `browser_connect_url: ${redactUrl(result.browser_connect_url)}`,
    `expected_site_origin: ${redactUrl(result.expected_site_origin)}`,
    "",
  ];

  if (result.failures.length === 0) {
    lines.push("No failures.");
  } else {
    lines.push("## Failure Buckets", "");
    for (const bucket of result.failure_summary) {
      lines.push(`- ${bucket.code}: ${bucket.count}`);
    }

    lines.push("", "## Failures", "");
    for (const checkFailure of result.failures) {
      lines.push(`- ${formatFailureLine(checkFailure)}`);
    }
  }

  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, `${lines.join("\n")}\n`);
}

export function printRouteSummary(routeResult) {
  const status = routeResult.result === "pass" ? "PASS" : "FAIL";
  printStatusLine(`${status} ${routeResult.label} ${routeResult.path}`);
}

export function printFailureSummary(result) {
  printStatusLine("preview page acceptance failed");

  for (const bucket of result.failure_summary) {
    printStatusLine(`  ${bucket.code}: ${bucket.count}`);
    for (const example of bucket.examples) {
      printStatusLine(`    ${formatFailureLine(example)}`);
    }
  }
}

export function printStatusLine(message) {
  console.error(message);
}

function summarizeFailures(failures) {
  const buckets = new Map();

  for (const failure of failures) {
    const bucket = buckets.get(failure.code) ?? {
      code: failure.code,
      count: 0,
      examples: [],
    };

    bucket.count += 1;

    if (bucket.examples.length < 2) {
      bucket.examples.push(failure);
    }

    buckets.set(failure.code, bucket);
  }

  return Array.from(buckets.values()).sort((left, right) =>
    left.code.localeCompare(right.code),
  );
}

function formatFailureLine(failure) {
  const detail = firstUsefulDetail(failure);

  if (detail === null) {
    return `${failure.route} [${failure.viewport}] ${failure.code}`;
  }

  return `${failure.route} [${failure.viewport}] ${failure.code}: ${detail}`;
}

function firstUsefulDetail(failure) {
  const formatter = failureDetailFormatters[failure.code];

  if (formatter !== undefined) {
    return formatter(failure);
  }

  if (failure.problem !== undefined) {
    return sanitizeDetail(failure.problem);
  }

  if (failure.text !== undefined) {
    return JSON.stringify(sanitizeDetail(failure.text));
  }

  if (failure.value !== undefined) {
    return JSON.stringify(sanitizeDetail(failure.value));
  }

  if (failure.url !== undefined) {
    return `${failure.status ?? ""} ${sanitizeDetail(failure.url)}`.trim();
  }

  if (failure.message !== undefined) {
    return sanitizeDetail(failure.message.split("\n")[0]);
  }

  if (failure.name !== undefined) {
    return failure.name;
  }

  return null;
}

function redactUrl(value) {
  if (typeof value !== "string") {
    return value;
  }

  const shouldRedact =
    process.env.PREVIEW_DEPLOY_REDACT_PUBLIC_URLS === "1" ||
    process.env.GITHUB_ACTIONS === "true";

  return shouldRedact
    ? value.replaceAll(
        /http:\/\/(?:\d{1,3}\.){3}\d{1,3}:\d{2,5}/g,
        "stored in deploy receipt",
      )
    : value;
}

function sanitizeDetail(value) {
  if (typeof value !== "string") {
    return value;
  }

  return redactUrl(value)
    .replaceAll(/\bdop_v1_[A-Za-z0-9_-]{8,}/g, "redacted DigitalOcean token")
    .replaceAll(/\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{20,}/g, "redacted GitHub token")
    .replaceAll(/\bgithub_pat_[A-Za-z0-9_]{20,}/g, "redacted GitHub token");
}
