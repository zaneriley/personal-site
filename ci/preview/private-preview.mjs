#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { spawn } from "node:child_process";

const repoRoot = process.cwd();

const exitStatus = await main(process.argv.slice(2));
process.exit(exitStatus);

async function main(args) {
  const options = parseOptions(args);
  const paths = previewPaths(options.outputDir);

  await fs.mkdir(options.outputDir, { recursive: true });
  await fs.writeFile(
    path.join(options.outputDir, "README.txt"),
    "Private preview evidence. deploy-receipt.json is the canonical result.\n",
  );

  await fs.rm(paths.runtimeDir, { force: true, recursive: true });
  await fs.rm(paths.pageDir, { force: true, recursive: true });
  await fs.mkdir(paths.hostDir, { recursive: true });
  await fs.mkdir(paths.runtimeDir, { recursive: true });
  await fs.mkdir(paths.pageDir, { recursive: true });

  if (!(await fileExists(paths.hostReceipt))) {
    await runTask(options.runner, "host:disposable:create", [], {
      DO_HOST_OUTPUT: paths.hostReceipt,
      PREVIEW_DEPLOY_ATTEMPT_ID: options.attemptId,
    });
  }

  const host = await readOptionalJson(paths.hostReceipt);
  if (host?.lifecycle_status === "ready") {
    await runTask(
      options.runner,
      "host:disposable:runtime-viability",
      [paths.hostReceipt],
      {
        APP_IMAGE_REF: options.appImageRef,
        PREVIEW_DEPLOY_ATTEMPT_ID: options.attemptId,
        RUNTIME_VIABILITY_OUTPUT: paths.runtimeReceipt,
        RUNTIME_VIABILITY_ARTIFACT_DIR: paths.runtimeDir,
      },
    );
  }

  const runtime = await readOptionalJson(paths.runtimeReceipt);
  if (runtime?.status === "pass") {
    await runTask(
      options.runner,
      "ci:preview-page-acceptance",
      [
        runtime.public_base_url,
        runtime.preview_page_acceptance?.expected_site_origin ??
          runtime.public_base_url,
      ],
      {
        PREVIEW_PAGE_ACCEPTANCE_IMAGE_REF: options.previewPageAcceptanceImage,
        PREVIEW_DEPLOY_ATTEMPT_ID: options.attemptId,
        PREVIEW_PAGE_ACCEPTANCE_OUTPUT_DIR: paths.pageDir,
      },
    );
  }

  const receipt = await buildReceipt(options, paths);
  await writeJson(paths.receipt, receipt);

  if (receipt.outcome !== "reviewable") {
    await fs.writeFile(paths.failureSummary, `${renderFailureSummary(receipt)}\n`);
  }

  if (options.githubSummary !== null) {
    await fs.writeFile(options.githubSummary, `${renderSummary(receipt)}\n`);
  }

  console.log(renderTerminal(receipt));
  return receipt.outcome === "reviewable" ? 0 : 1;
}

function parseOptions(args) {
  const appImageRef = requiredOption(args, "--app-image-ref");
  const appSha = requiredOption(args, "--app-sha");
  const previewPageAcceptanceImage = requiredOption(
    args,
    "--preview-page-acceptance-image",
  );
  const runner = process.env.PRIVATE_PREVIEW_RUNNER ?? "./run";
  const outputDir = path.resolve(
    optionValue(args, "--output-dir", ".tmp/ci-artifacts/preview"),
  );

  if (!/@sha256:[0-9a-fA-F]{64}$/.test(appImageRef)) {
    fail("--app-image-ref must be digest-pinned");
  }

  if (process.env.GITHUB_ACTIONS === "true" && process.env.PRIVATE_PREVIEW_RUNNER) {
    fail("PRIVATE_PREVIEW_RUNNER is not allowed in GitHub Actions");
  }

  return {
    appImageRef,
    appSha,
    previewPageAcceptanceImage,
    outputDir,
    runner,
    attemptId:
      process.env.PREVIEW_DEPLOY_ATTEMPT_ID ?? crypto.randomBytes(16).toString("hex"),
    githubSummary: process.env.GITHUB_STEP_SUMMARY ?? null,
  };
}

async function buildReceipt(options, paths) {
  const host = await readOptionalJson(paths.hostReceipt);
  const runtime = await readOptionalJson(paths.runtimeReceipt);
  const pageChecks = await readOptionalJson(paths.pageReceipt);
  const failure = firstFailure({ host, runtime, pageChecks, options });

  return {
    schema_version: 1,
    receipt_type: "private_preview",
    preview_deploy_attempt_id: options.attemptId,
    outcome: failure === null ? "reviewable" : "blocked",
    generated_at: new Date().toISOString(),
    candidate: {
      app_image_ref: options.appImageRef,
      app_image_digest: imageDigest(options.appImageRef),
      app_git_sha: options.appSha,
    },
    evidence: {
      root: relative(paths.outputDir),
      receipt: relative(paths.receipt),
      failure_summary: relative(paths.failureSummary),
      runtime_viability: relative(paths.runtimeReceipt),
      preview_page_acceptance: relative(paths.pageReceipt),
      screenshots: relative(path.join(paths.pageDir, "screenshots")),
    },
    host: {
      kind: "disposable_host",
      lifecycle: "disposable",
      provider: host?.provider ?? null,
      lifecycle_status: host?.lifecycle_status ?? null,
      droplet_id: host?.droplet_id ?? null,
      public_ipv4: host?.public_ipv4 ?? null,
      region: host?.region ?? null,
      size: host?.size ?? null,
    },
    preview: {
      url: runtime?.public_base_url ?? publicUrl(host),
      expected_site_origin:
        runtime?.preview_page_acceptance?.expected_site_origin ??
        runtime?.public_base_url ??
        publicUrl(host),
    },
    checks: {
      host: checkHost(host, options.attemptId),
      runtime_viability: checkRuntime(runtime, options),
      preview_page_acceptance: checkPageChecks(pageChecks, runtime, options),
    },
    content: {
      sha: runtime?.content_status?.live_content_sha ?? null,
      generation_id:
        runtime?.content_status?.live_content_publication_generation_id ?? null,
      publication_flow: runtime?.content_publication_flow ?? null,
    },
    resources: {
      web_memory_peak_bytes: memoryPeak(runtime, "web"),
      postgres_memory_peak_bytes: memoryPeak(runtime, "postgres"),
    },
    commands: {
      destroy:
        host?.droplet_id && host?.lifecycle_status === "ready"
          ? `./run preview:destroy ${relative(paths.receipt)}`
          : null,
    },
    failure,
  };
}

function firstFailure({ host, runtime, pageChecks, options }) {
  const hostCheck = checkHost(host, options.attemptId);
  if (hostCheck.status !== "pass") {
    return failure("host", hostCheck.reason, "Disposable host was not ready.");
  }

  const runtimeCheck = checkRuntime(runtime, options);
  if (runtimeCheck.status !== "pass") {
    return failure(
      "runtime_viability",
      runtimeCheck.reason,
      "Candidate image did not pass runtime viability.",
    );
  }

  const pageCheck = checkPageChecks(pageChecks, runtime, options);
  if (pageCheck.status !== "pass") {
    return failure(
      "preview_page_acceptance",
      pageCheck.reason,
      "Preview page acceptance did not pass.",
    );
  }

  return null;
}

function checkHost(host, attemptId) {
  if (host === null) return { status: "fail", reason: "missing_host_receipt" };
  if (host.preview_deploy_attempt_id !== attemptId) {
    return { status: "fail", reason: "stale_host_receipt" };
  }
  if (host.lifecycle_status !== "ready") {
    return { status: "fail", reason: `host_${host.lifecycle_status ?? "not_ready"}` };
  }
  return { status: "pass" };
}

function checkRuntime(runtime, options) {
  if (runtime === null) return { status: "not_run", reason: "missing_runtime_receipt" };
  if (runtime.preview_deploy_attempt_id !== options.attemptId) {
    return { status: "fail", reason: "stale_runtime_receipt" };
  }
  if (runtime.app_image_ref !== options.appImageRef) {
    return { status: "fail", reason: "wrong_app_image" };
  }
  if (runtime.status !== "pass") {
    return { status: "fail", reason: runtime.failure_reason ?? "runtime_failed" };
  }
  return { status: "pass" };
}

function checkPageChecks(pageChecks, runtime, options) {
  if (runtime?.status !== "pass") return { status: "not_run" };
  if (pageChecks === null) {
    return { status: "not_run", reason: "missing_preview_page_acceptance" };
  }
  if (pageChecks.preview_deploy_attempt_id !== options.attemptId) {
    return { status: "fail", reason: "stale_preview_page_acceptance" };
  }
  if (
    pageChecks.preview_page_acceptance_image_ref !==
    options.previewPageAcceptanceImage
  ) {
    return { status: "fail", reason: "wrong_preview_page_acceptance_image" };
  }
  if (pageChecks.status !== "pass") {
    return {
      status: "fail",
      reason: pageChecks.failures?.[0]?.code ?? "preview_page_acceptance_failed",
    };
  }
  return { status: "pass" };
}

async function runTask(runner, task, args, env) {
  const result = await spawnTask(runner, [task, ...args], env);

  process.stdout.write(redactPublicPreviewUrls(result.stdout));

  if (result.status !== 0) {
    process.stderr.write(redactPublicPreviewUrls(result.stderr));
  }
}

function spawnTask(command, args, env) {
  return new Promise((resolve, reject) => {
    let stdout = "";
    let stderr = "";
    const child = spawn(command, args, {
      cwd: repoRoot,
      env: { ...process.env, ...env },
      stdio: ["ignore", "pipe", "pipe"],
    });
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

function renderTerminal(receipt) {
  const previewUrl = displayPreviewUrl(receipt);
  const lines = [
    "Private preview",
    "",
    `  outcome      ${receipt.outcome.toUpperCase()}`,
    `  app image    ${receipt.candidate.app_image_ref}`,
    `  commit       ${receipt.candidate.app_git_sha.slice(0, 12)}`,
    `  preview      ${previewUrl}`,
    `  receipt      ${receipt.evidence.receipt}`,
  ];

  if (receipt.failure !== null) {
    lines.push(
      `  failed       ${receipt.failure.stage}`,
      `  reason       ${receipt.failure.reason}`,
      `  summary      ${receipt.failure.summary}`,
      `  details      ${receipt.evidence.failure_summary}`,
    );
  }

  lines.push(`  destroy      ${receipt.commands.destroy ?? "not available"}`, "");
  lines.push(
    receipt.outcome === "reviewable"
      ? "This private preview is ready for review."
      : "This private preview is blocked. Use the receipt and failure summary.",
  );

  return lines.join("\n");
}

function renderSummary(receipt) {
  const previewUrl = displayPreviewUrl(receipt);

  return [
    `## Private preview: ${receipt.outcome.toUpperCase()}`,
    "",
    `- App image: \`${receipt.candidate.app_image_ref}\``,
    `- Commit: \`${receipt.candidate.app_git_sha}\``,
    `- Receipt: \`${receipt.evidence.receipt}\``,
    `- Preview URL: ${previewUrl}`,
    `- Destroy: \`${receipt.commands.destroy ?? "not available"}\``,
    ...(receipt.failure === null
      ? ["", "Private preview is ready for review."]
      : [
          "",
          `Blocked at \`${receipt.failure.stage}\`: ${receipt.failure.summary}`,
        ]),
  ].join("\n");
}

function displayPreviewUrl(receipt) {
  if (process.env.PREVIEW_DEPLOY_REDACT_PUBLIC_URLS === "1") {
    return receipt.preview.url === null || receipt.preview.url === undefined
      ? "not available"
      : "see deploy-receipt.json artifact";
  }

  return receipt.preview.url ?? "not available";
}

function redactPublicPreviewUrls(content) {
  if (process.env.PREVIEW_DEPLOY_REDACT_PUBLIC_URLS !== "1") {
    return content;
  }

  return content.replaceAll(
    /http:\/\/(?:\d{1,3}\.){3}\d{1,3}:\d{2,5}\b/g,
    "see deploy-receipt.json artifact",
  );
}

function imageDigest(imageRef) {
  return imageRef.match(/@(sha256:[0-9a-fA-F]{64})$/)?.[1]?.toLowerCase() ?? null;
}

function renderFailureSummary(receipt) {
  return [
    "# Private Preview Blocked",
    "",
    `- Stage: ${receipt.failure.stage}`,
    `- Reason: ${receipt.failure.reason}`,
    `- Summary: ${receipt.failure.summary}`,
    `- Receipt: ${receipt.evidence.receipt}`,
    `- Destroy: ${receipt.commands.destroy ?? "not available"}`,
  ].join("\n");
}

function previewPaths(outputDir) {
  const stages = path.join(outputDir, "stages");
  const hostDir = path.join(stages, "host");
  const runtimeDir = path.join(stages, "runtime-viability");
  const pageDir = path.join(stages, "preview-page-acceptance");
  return {
    outputDir,
    hostDir,
    runtimeDir,
    pageDir,
    receipt: path.join(outputDir, "deploy-receipt.json"),
    failureSummary: path.join(outputDir, "failure-summary.md"),
    hostReceipt: path.join(hostDir, "digitalocean-host.json"),
    runtimeReceipt: path.join(runtimeDir, "runtime-viability.json"),
    pageReceipt: path.join(pageDir, "preview-page-acceptance.json"),
  };
}

async function fileExists(filePath) {
  try {
    await fs.stat(filePath);
    return true;
  } catch (error) {
    if (error.code === "ENOENT") return false;
    throw error;
  }
}

async function readOptionalJson(filePath) {
  try {
    return JSON.parse(await fs.readFile(filePath, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") return null;
    throw error;
  }
}

async function writeJson(filePath, value) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`);
}

function publicUrl(host) {
  return host?.public_ipv4 ? `http://${host.public_ipv4}:18080` : null;
}

function memoryPeak(runtime, label) {
  return (
    runtime?.memory_peaks?.find((entry) => entry.container?.includes(label))
      ?.peak_bytes ?? null
  );
}

function failure(stage, reason, summary) {
  return { stage, reason, summary };
}

function requiredOption(args, name) {
  const value = optionValue(args, name, null);
  if (value === null || value === undefined || value === "" || value.startsWith("--")) {
    fail(`${name} is required`);
  }
  return value;
}

function optionValue(args, name, fallback) {
  const index = args.indexOf(name);
  return index === -1 ? fallback : args[index + 1];
}

function relative(filePath) {
  return path.relative(repoRoot, filePath);
}

function fail(message) {
  console.error(`fatal: ${message}`);
  process.exit(64);
}
