#!/usr/bin/env node

import { spawn } from "node:child_process";
import fs from "node:fs/promises";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptPath = fileURLToPath(import.meta.url);
const scriptDir = path.dirname(scriptPath);
const repoRoot = path.resolve(scriptDir, "../..");
const runnerPath = path.join(scriptDir, "preview-browser-check.mjs");
const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "preview-browser-check-"));
const externalServer = await startServer((request, response) => {
  if (request.url === "/external.png") {
    response.writeHead(200, { "content-type": "image/png" });
    response.end(emptyPng());
    return;
  }

  response.writeHead(404, { "content-type": "text/plain" });
  response.end("not found");
});
const externalOrigin = `http://127.0.0.1:${externalServer.port}`;
const fixtureServer = await startServer((request, response) => {
  respondToFixtureRequest(request, response, externalOrigin);
});
const fixtureOrigin = `http://127.0.0.1:${fixtureServer.port}`;

try {
  await assertPass("passes a healthy page", {
    route: "/pass",
    requiredText: ["Ready Content"],
  });

  await assertFailure("fails when required body text is missing", {
    route: "/missing-text",
    requiredText: ["Ready Content"],
    code: "missing_visible_text",
  });

  await assertFailure("fails when forbidden error copy is visible", {
    route: "/forbidden",
    requiredText: ["Ready Content"],
    code: "forbidden_visible_text",
  });

  await assertFailure("fails when a first-party asset returns an error", {
    route: "/bad-asset",
    requiredText: ["Ready Content"],
    code: "bad_response_status",
  });

  await assertFailure("fails when a page fetches a response from another origin", {
    route: "/wrong-origin-response",
    requiredText: ["Ready Content"],
    code: "wrong_origin_response",
  });

  await assertFailure("fails when share URLs use the wrong site origin", {
    route: "/wrong-dom-origin",
    requiredText: ["Ready Content"],
    code: "wrong_site_origin_in_dom",
    issue: "origin_mismatch",
  });

  await assertFailure("fails when present share URLs are root-relative", {
    route: "/relative-dom-url",
    requiredText: ["Ready Content"],
    code: "wrong_site_origin_in_dom",
    issue: "non_absolute_value",
  });

  await assertFailure("fails on CSP violations", {
    route: "/csp-violation",
    requiredText: ["Ready Content"],
    code: "csp_violation",
  });

  console.error("preview browser check fixture tests passed");
} finally {
  await fixtureServer.close();
  await externalServer.close();
  await fs.rm(tmpDir, { force: true, recursive: true });
}

async function assertPass(name, options) {
  const result = await runFixture(name, options);

  if (result.status !== 0) {
    throw new Error(`${name}: expected pass, got exit ${result.status}`);
  }

  const output = await readJson(result.outputPath);

  if (output.status !== "pass") {
    throw new Error(`${name}: expected output status pass`);
  }
}

async function assertFailure(name, options) {
  const result = await runFixture(name, options);

  if (result.status === 0) {
    throw new Error(`${name}: expected failure`);
  }

  const output = await readJson(result.outputPath);
  const matchingFailure = output.failures.find(
    (failure) =>
      failure.code === options.code &&
      (options.issue === undefined || failure.issue === options.issue),
  );

  if (matchingFailure === undefined) {
    throw new Error(
      `${name}: expected ${options.code}, got ${output.failures
        .map((failure) => `${failure.code}:${failure.issue ?? ""}`)
        .join(", ")}`,
    );
  }
}

async function runFixture(name, options) {
  const slug = name.replaceAll(/[^a-z0-9]+/gi, "-").replaceAll(/^-|-$/g, "");
  const routesPath = path.join(tmpDir, `${slug}-routes.json`);
  const outputPath = path.join(tmpDir, `${slug}-output.json`);
  const screenshotsDir = path.join(tmpDir, `${slug}-screenshots`);

  await fs.writeFile(
    routesPath,
    `${JSON.stringify(routeConfig(options.route, options.requiredText), null, 2)}\n`,
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

  return { ...result, outputPath };
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

function routeConfig(route, requiredText) {
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
        label: "fixture",
        path: route,
        allowed_statuses: [200],
        required_text: requiredText,
      },
    ],
  };
}

function respondToFixtureRequest(request, response, externalOrigin) {
  const route = request.url ?? "/";

  if (route === "/style.css") {
    response.writeHead(200, { "content-type": "text/css" });
    response.end("main { display: block; }");
    return;
  }

  if (route === "/app.js") {
    response.writeHead(200, { "content-type": "application/javascript" });
    response.end("window.previewFixtureLoaded = true;");
    return;
  }

  if (route === "/missing.js") {
    response.writeHead(404, { "content-type": "text/plain" });
    response.end("missing");
    return;
  }

  if (route === "/favicon.ico") {
    response.writeHead(204);
    response.end();
    return;
  }

  if (route === "/missing-text") {
    sendHtml(response, fixtureHtml({ body: "Different Content" }));
    return;
  }

  if (route === "/forbidden") {
    sendHtml(response, fixtureHtml({ body: "Ready Content Visible Error" }));
    return;
  }

  if (route === "/bad-asset") {
    sendHtml(
      response,
      fixtureHtml({
        body: "Ready Content",
        head: '<script src="/missing.js"></script>',
      }),
    );
    return;
  }

  if (route === "/wrong-origin-response") {
    sendHtml(
      response,
      fixtureHtml({
        body: "Ready Content",
        head: `<img src="${externalOrigin}/external.png" alt="">`,
      }),
    );
    return;
  }

  if (route === "/wrong-dom-origin") {
    sendHtml(
      response,
      fixtureHtml({
        body: "Ready Content",
        ogUrl: "https://wrong.example/wrong-dom-origin",
      }),
    );
    return;
  }

  if (route === "/relative-dom-url") {
    sendHtml(
      response,
      fixtureHtml({
        body: "Ready Content",
        ogImage: "/images/og-default.png",
      }),
    );
    return;
  }

  if (route === "/csp-violation") {
    sendHtml(
      response,
      fixtureHtml({
        body: "Ready Content",
        head: "<style>main { color: red; }</style>",
      }),
      {
        "content-security-policy": "default-src 'self'; style-src 'none'",
      },
    );
    return;
  }

  sendHtml(response, fixtureHtml({ body: "Ready Content" }));
}

function fixtureHtml(options = {}) {
  const origin = fixtureOrigin;
  const ogUrl = options.ogUrl ?? `${origin}/pass`;
  const ogImage = options.ogImage ?? `${origin}/images/og-default.png`;

  return `<!doctype html>
<html>
  <head>
    <title>Fixture</title>
    <link rel="stylesheet" href="/style.css">
    <meta property="og:title" content="Fixture Title">
    <meta property="og:description" content="Fixture Description">
    <meta property="og:url" content="${escapeHtml(ogUrl)}">
    <meta property="og:image" content="${escapeHtml(ogImage)}">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="Fixture Title">
    <meta name="twitter:description" content="Fixture Description">
    <meta name="twitter:image" content="${escapeHtml(ogImage)}">
    ${options.head ?? ""}
  </head>
  <body>
    <main>${escapeHtml(options.body ?? "Ready Content")}</main>
  </body>
</html>`;
}

function sendHtml(response, html, headers = {}) {
  response.writeHead(200, { "content-type": "text/html", ...headers });
  response.end(html);
}

function startServer(handler) {
  const server = http.createServer(handler);

  return new Promise((resolve, reject) => {
    server.on("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();

      resolve({
        port: address.port,
        close: () =>
          new Promise((closeResolve, closeReject) => {
            server.close((error) => {
              if (error) {
                closeReject(error);
                return;
              }

              closeResolve();
            });
          }),
      });
    });
  });
}

async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, "utf8"));
}

function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function emptyPng() {
  return Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "base64",
  );
}
