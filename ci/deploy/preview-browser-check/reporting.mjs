import fs from "node:fs/promises";
import path from "node:path";

const failureDetailFormatters = {
  bad_document_status: (failure) =>
    `status ${failure.status}; allowed ${failure.allowed_statuses.join(", ")}`,
  csp_violation: (failure) =>
    `${failure.violated_directive}: ${failure.blocked_uri}`,
  live_view_not_connected: (failure) =>
    `app_js_loaded=${failure.app_js_loaded} live_socket_present=${failure.live_socket_present}`,
  missing_required_dom: (failure) => `${failure.selector}: ${failure.reason}`,
  missing_share_metadata: (failure) => failure.name,
  viewport_overflow: (failure) =>
    `document ${failure.document_scroll_width}px > viewport ${failure.viewport_width}px`,
  wrong_site_origin_in_dom: (failure) => {
    const expected =
      failure.expected_origin === undefined
        ? ""
        : ` expected ${failure.expected_origin}`;

    return `${failure.name} ${failure.issue}: ${JSON.stringify(failure.value)}${expected}`;
  },
};

export function buildResult({ plan, routes, failures }) {
  return {
    schema_version: 1,
    command: plan.command,
    generated_at: new Date().toISOString(),
    status: failures.length === 0 ? "pass" : "fail",
    browser_connect_url: plan.browserConnectUrl,
    expected_site_origin: plan.expectedSiteOrigin,
    allowed_response_origins: plan.allowedResponseOrigins,
    route_config_file: plan.routeConfigFile,
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
    `# preview_browser_check: ${result.status}`,
    "",
    `browser_connect_url: ${result.browser_connect_url}`,
    `expected_site_origin: ${result.expected_site_origin}`,
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
  printStatusLine("preview browser check failed");

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
    return failure.problem;
  }

  if (failure.text !== undefined) {
    return JSON.stringify(failure.text);
  }

  if (failure.value !== undefined) {
    return JSON.stringify(failure.value);
  }

  if (failure.url !== undefined) {
    return `${failure.status ?? ""} ${failure.url}`.trim();
  }

  if (failure.message !== undefined) {
    return failure.message.split("\n")[0];
  }

  if (failure.name !== undefined) {
    return failure.name;
  }

  return null;
}
