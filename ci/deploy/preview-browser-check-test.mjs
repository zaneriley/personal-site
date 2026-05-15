#!/usr/bin/env node

import { spawn } from "node:child_process";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { startPreviewFixtureServer } from "./preview-browser-check/fixture-server.mjs";

const scriptPath = fileURLToPath(import.meta.url);
const scriptDir = path.dirname(scriptPath);
const repoRoot = path.resolve(scriptDir, "../..");
const runnerPath = path.join(scriptDir, "preview-browser-check.mjs");
const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "preview-browser-check-"));
const cases = [
  {
    name: "healthy page proves the happy path",
    route: "/pass",
    page: {},
    expect: { status: "pass", failures: [] },
  },
  {
    name: "required visible text must render",
    route: "/missing-text",
    page: { body: "Different Content" },
    expect: {
      status: "fail",
      failures: [{ code: "missing_visible_text", text: "Ready Content" }],
    },
  },
  {
    name: "visible error copy must fail the preview",
    route: "/forbidden",
    page: { body: "Ready Content Visible Error" },
    expect: {
      status: "fail",
      failures: [{ code: "forbidden_visible_text", text: "Visible Error" }],
    },
  },
  {
    name: "first party assets must not return errors",
    route: "/bad-asset",
    page: {
      body: "Ready Content",
      head: '<script src="/missing.js"></script>',
    },
    expect: {
      status: "fail",
      failures: [{ code: "bad_response_status", status: 404 }],
    },
  },
  {
    name: "browser responses must stay on the preview fetch origin",
    route: "/wrong-origin-response",
    page: {
      body: "Ready Content",
      externalImage: true,
    },
    expect: {
      status: "fail",
      failures: [{ code: "wrong_origin_response" }],
    },
  },
  {
    name: "share urls must use the expected site origin",
    route: "/wrong-dom-origin",
    page: {
      body: "Ready Content",
      ogUrl: "https://wrong.example/wrong-dom-origin",
    },
    expect: {
      status: "fail",
      failures: [
        {
          code: "wrong_site_origin_in_dom",
          issue: "origin_mismatch",
          name: "og:url",
          origin: "https://wrong.example",
        },
      ],
    },
  },
  {
    name: "present share image urls must be absolute",
    route: "/relative-dom-url",
    page: {
      body: "Ready Content",
      ogImage: "/images/og-default.png",
    },
    expect: {
      status: "fail",
      failures: [
        {
          code: "wrong_site_origin_in_dom",
          issue: "non_absolute_value",
          name: "og:image",
          value: "/images/og-default.png",
        },
      ],
    },
  },
  {
    name: "csp violations must fail the preview",
    route: "/csp-violation",
    page: {
      body: "Ready Content",
      head: "<style>main { color: red; }</style>",
      headers: {
        "content-security-policy": "default-src 'self'; style-src 'none'",
      },
    },
    expect: {
      status: "fail",
      failures: [{ code: "csp_violation", violated_directive: "style-src-elem" }],
    },
  },
  {
    name: "share metadata must exist on checked pages",
    route: "/missing-share-metadata",
    page: {
      body: "Ready Content",
      shareMetadata: false,
    },
    expect: {
      status: "fail",
      failures: [{ code: "missing_share_metadata", name: "og:title" }],
    },
  },
  {
    name: "internal host leaks must fail the preview",
    route: "/wrong-host-text",
    page: {
      body: "Ready Content",
      head: '<script type="application/json">{"origin":"preview.local"}</script>',
    },
    expect: {
      status: "fail",
      failures: [{ code: "wrong_host_text", text: "preview.local" }],
    },
  },
];

const fixtureServer = await startPreviewFixtureServer(cases);

try {
  for (const testCase of cases) {
    await assertCase(testCase, fixtureServer.origin);
  }

  console.error("preview browser check fixture tests passed");
} finally {
  await fixtureServer.close();
  await fs.rm(tmpDir, { force: true, recursive: true });
}

async function assertCase(testCase, fixtureOrigin) {
  const result = await runFixture(testCase, fixtureOrigin);
  const output = await readJson(result.outputPath);

  if (result.status === 0 && testCase.expect.status !== "pass") {
    throw new Error(formatCaseDebug(testCase, result, output));
  }

  if (result.status !== 0 && testCase.expect.status === "pass") {
    throw new Error(formatCaseDebug(testCase, result, output));
  }

  if (output.status !== testCase.expect.status) {
    throw new Error(formatCaseDebug(testCase, result, output));
  }

  for (const expectedFailure of testCase.expect.failures) {
    const matchingFailure = output.failures.find((failure) =>
      failureMatches(expectedFailure, failure),
    );

    if (matchingFailure === undefined) {
      throw new Error(formatCaseDebug(testCase, result, output));
    }
  }
}

async function runFixture(testCase, fixtureOrigin) {
  const slug = slugify(testCase.name);
  const routesPath = path.join(tmpDir, `${slug}-routes.json`);
  const outputPath = path.join(tmpDir, `${slug}-output.json`);
  const screenshotsDir = path.join(tmpDir, `${slug}-screenshots`);

  await fs.writeFile(
    routesPath,
    `${JSON.stringify(routeConfig(testCase, fixtureOrigin), null, 2)}\n`,
  );

  const result = await spawnRunner(process.execPath, [
    runnerPath,
    "--browser-connect-url",
    fixtureOrigin,
    "--expected-site-origin",
    fixtureOrigin,
    "--routes-json",
    routesPath,
    "--screenshots-dir",
    screenshotsDir,
    "--output",
    outputPath,
  ]);

  return { ...result, outputPath, routesPath, screenshotsDir };
}

function spawnRunner(command, commandArgs) {
  return new Promise((resolve, reject) => {
    let stderr = "";
    let stdout = "";
    const child = spawn(command, commandArgs, { cwd: repoRoot });

    child.stdout.on("data", (chunk) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.on("error", reject);
    child.on("close", (status) => {
      resolve({ status, stderr, stdout });
    });
  });
}

function routeConfig(testCase) {
  return {
    schema_version: 1,
    viewports: [{ label: "desktop", width: 800, height: 600 }],
    browser_defaults: {
      required_dom: ["main"],
      require_share_metadata: true,
      screenshot: false,
    },
    forbidden_text: ["Visible Error"],
    wrong_host_text: ["preview.local", "web:8000"],
    routes: [
      {
        label: slugify(testCase.name),
        path: testCase.route,
        allowed_statuses: [200],
        required_text: ["Ready Content"],
      },
    ],
  };
}

function failureMatches(expectedFailure, observedFailure) {
  return Object.entries(expectedFailure).every(
    ([key, value]) => observedFailure[key] === value,
  );
}

function formatCaseDebug(testCase, result, output) {
  return [
    `${testCase.name}: preview browser fixture assertion failed`,
    `exit_status: ${result.status}`,
    `expected: ${JSON.stringify(testCase.expect, null, 2)}`,
    `observed_status: ${output.status}`,
    `observed_failures: ${JSON.stringify(output.failures, null, 2)}`,
    `stdout: ${result.stdout.trim()}`,
    `stderr: ${result.stderr.trim()}`,
    `routes_path: ${result.routesPath}`,
    `output_path: ${result.outputPath}`,
    `screenshots_dir: ${result.screenshotsDir}`,
  ].join("\n");
}

async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, "utf8"));
}

function slugify(value) {
  return value.replaceAll(/[^a-z0-9]+/gi, "-").replaceAll(/^-|-$/g, "");
}
