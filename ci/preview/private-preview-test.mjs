#!/usr/bin/env node

import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";

const repoRoot = path.resolve(new URL("../..", import.meta.url).pathname);
const runner = path.join(repoRoot, "ci/preview/private-preview.mjs");
const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "private-preview-"));
const digest = "a".repeat(64);
const appImage = `ghcr.io/zaneriley/personal-site@sha256:${digest}`;
const previewPageAcceptanceImage = "personal-site-preview-page-acceptance:trusted";

try {
  await assertCase("reviewable", { status: 0, outcome: "reviewable" });
  await assertCase("runtime-fails", {
    status: 1,
    outcome: "blocked",
    stage: "runtime_viability",
    reason: "route_probe_failed",
  });
  await assertCase("page-fails", {
    status: 1,
    outcome: "blocked",
    stage: "preview_page_acceptance",
    reason: "wrong_site_origin_in_dom",
  });
  await assertCase("no-host", {
    status: 1,
    outcome: "blocked",
    stage: "host",
    reason: "missing_host_receipt",
  });
  console.error("private preview fixture tests passed");
} finally {
  await fs.rm(tmpDir, { force: true, recursive: true });
}

async function assertCase(name, expected) {
  const root = path.join(tmpDir, name);
  const outputDir = path.join(root, "preview");
  const fakeRunner = await writeFakeRunner(root);
  const result = await run(
    [
      runner,
      "--app-image-ref",
      appImage,
      "--app-sha",
      "abc123def456",
      "--preview-page-acceptance-image",
      previewPageAcceptanceImage,
      "--output-dir",
      outputDir,
    ],
    {
      PRIVATE_PREVIEW_RUNNER: fakeRunner,
      PREVIEW_DEPLOY_ATTEMPT_ID: `attempt-${name}`,
      PRIVATE_PREVIEW_FIXTURE: name,
    },
  );
  const receipt = await readJson(path.join(outputDir, "deploy-receipt.json"));

  assertEqual(result.status, expected.status, `${name} exit status`);
  assertEqual(receipt.outcome, expected.outcome, `${name} outcome`);
  assertEqual(receipt.host.kind, "disposable_host", `${name} host kind`);
  assertEqual(receipt.host.lifecycle, "disposable", `${name} host lifecycle`);

  if (expected.stage !== undefined) {
    assertEqual(receipt.failure.stage, expected.stage, `${name} failure stage`);
    assertEqual(receipt.failure.reason, expected.reason, `${name} failure reason`);
  } else {
    assertEqual(receipt.failure, null, `${name} failure`);
    assertEqual(
      receipt.content.publication_flow.status,
      "ready_for_rehearsal",
      `${name} publication flow status`,
    );
  }
}

async function writeFakeRunner(root) {
  const fakeRunner = path.join(root, "fake-runner.mjs");
  await fs.mkdir(root, { recursive: true });
  await fs.writeFile(
    fakeRunner,
    `#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";

const task = process.argv[2];
const fixture = process.env.PRIVATE_PREVIEW_FIXTURE;

if (task === "host:disposable:create") await host();
else if (task === "host:disposable:runtime-viability") await runtime();
else if (task === "ci:preview-page-acceptance") await pageChecks();
else throw new Error("unexpected task " + task);

async function host() {
  if (fixture === "no-host") process.exit(1);
  await writeJson(process.env.DO_HOST_OUTPUT, {
    preview_deploy_attempt_id: process.env.PREVIEW_DEPLOY_ATTEMPT_ID,
    provider: "digitalocean",
    lifecycle_status: "ready",
    droplet_id: "123",
    public_ipv4: "203.0.113.42",
    region: "sfo3",
    size: "s-1vcpu-1gb"
  });
}

async function runtime() {
  const pass = fixture !== "runtime-fails";
  await writeJson(process.env.RUNTIME_VIABILITY_OUTPUT, {
    preview_deploy_attempt_id: process.env.PREVIEW_DEPLOY_ATTEMPT_ID,
    status: pass ? "pass" : "fail",
    failure_reason: pass ? null : "route_probe_failed",
    app_image_ref: process.env.APP_IMAGE_REF,
    public_base_url: "http://203.0.113.42:18080",
    preview_page_acceptance: { expected_site_origin: "http://203.0.113.42:18080" },
    content_publication_flow: {
      status: "ready_for_rehearsal",
      content_base_path: "/app/content-publication/content",
      content_repo_url: "file:///app/content-publication/content-source.git"
    },
    content_status: {
      live_content_sha: "content-sha",
      live_content_publication_generation_id: 7
    },
    memory_peaks: [
      { container: "personal-site-web-1", peak_bytes: 1234 },
      { container: "personal-site-postgres-1", peak_bytes: 5678 }
    ]
  });
  if (!pass) process.exit(1);
}

async function pageChecks() {
  const pass = fixture !== "page-fails";
  await writeJson(path.join(process.env.PREVIEW_PAGE_ACCEPTANCE_OUTPUT_DIR, "preview-page-acceptance.json"), {
    preview_deploy_attempt_id: process.env.PREVIEW_DEPLOY_ATTEMPT_ID,
    preview_page_acceptance_image_ref: process.env.PREVIEW_PAGE_ACCEPTANCE_IMAGE_REF,
    status: pass ? "pass" : "fail",
    failures: pass ? [] : [{ code: "wrong_site_origin_in_dom" }]
  });
  if (!pass) process.exit(1);
}

async function writeJson(file, value) {
  await fs.mkdir(path.dirname(file), { recursive: true });
  await fs.writeFile(file, JSON.stringify(value, null, 2) + "\\n");
}
`,
  );
  await fs.chmod(fakeRunner, 0o755);
  return fakeRunner;
}

function run(args, env) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, args, {
      cwd: repoRoot,
      env: { ...process.env, ...env },
      stdio: ["ignore", "pipe", "pipe"],
    });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.on("error", reject);
    child.on("close", (status) => resolve({ status, stdout, stderr }));
  });
}

async function readJson(file) {
  return JSON.parse(await fs.readFile(file, "utf8"));
}

function assertEqual(observed, expected, label) {
  if (observed !== expected) {
    throw new Error(`${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(observed)}`);
  }
}
