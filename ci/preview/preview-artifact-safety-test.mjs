#!/usr/bin/env node

import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { scanArtifactTree } from "./preview-artifact-safety.mjs";

const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "preview-artifact-safety-"));
const previewUrl = "http://203.0.113.42:18080";
const forbiddenCases = [
  {
    name: "digitalocean token",
    file: "deploy.log",
    content: "DIGITALOCEAN_TOKEN=dop_v1_forbidden",
    expected: "DIGITALOCEAN_TOKEN",
  },
  {
    name: "ssh private key",
    file: "host.env",
    content: "DEPLOY_SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----",
    expected: "DEPLOY_SSH_PRIVATE_KEY",
  },
  {
    name: "ssh public key",
    file: "host.env",
    content: "DEPLOY_SSH_PUBLIC_KEY=ssh-ed25519 AAAAforbidden",
    expected: "DEPLOY_SSH_PUBLIC_KEY",
  },
  {
    name: "phoenix secret",
    file: "runtime.env",
    content: "SECRET_KEY_BASE=super-secret",
    expected: "SECRET_KEY_BASE=",
  },
  {
    name: "postgres password",
    file: "runtime.env",
    content: "POSTGRES_PASSWORD=super-secret",
    expected: "POSTGRES_PASSWORD=",
  },
  {
    name: "webhook secret",
    file: "runtime.env",
    content: "GITHUB_WEBHOOK_SECRET=super-secret",
    expected: "GITHUB_WEBHOOK_SECRET=",
  },
  {
    name: "runtime registry token",
    file: "runtime.env",
    content: "RUNTIME_VIABILITY_REGISTRY_TOKEN=ghp_forbidden",
    expected: "RUNTIME_VIABILITY_REGISTRY_TOKEN",
  },
  {
    name: "registry auth env path",
    file: "stages/runtime-viability/.registry-auth.env",
    content: "registry auth should never be artifacted",
    expected: ".registry-auth.env",
  },
  {
    name: "registry token path",
    file: "stages/runtime-viability/.registry-token",
    content: "registry token should never be artifacted",
    expected: ".registry-token",
  },
  {
    name: "docker auths object",
    file: "docker-config.json",
    content: JSON.stringify({ auths: { "ghcr.io": { auth: "forbidden" } } }),
    expected: "auths",
  },
  {
    name: "ghcr auth token",
    file: "docker-config.json",
    content: JSON.stringify({
      "ghcr.io": {
        auth: ["Z2hw", "X2ZvcmJpZGRlbjEy", "MzQ1Njc4OTA="].join(""),
      },
    }),
    expected: "docker auth value",
  },
  {
    name: "production origin in browser network output",
    file: "stages/preview-page-acceptance/network.json",
    content: JSON.stringify({
      responses: [{ url: "https://zaneriley.com/en/note/prod-build-smoke-note" }],
    }),
    expected: "production origin",
  },
  {
    name: "public preview url in terminal output",
    file: "terminal.txt",
    content: `preview URL      ${previewUrl}`,
    expected: "public preview URL",
  },
  {
    name: "public preview url in github summary",
    file: "github-summary.md",
    content: `| preview URL | ${previewUrl} |`,
    expected: "public preview URL",
  },
  {
    name: "public preview url in failure summary",
    file: "failure-summary.md",
    content: `- Preview URL: ${previewUrl}`,
    expected: "public preview URL",
  },
  {
    name: "percent encoded token",
    file: "compose-logs.txt",
    content: "dop%5Fv1%5Faaaaaaaaaaaaaaaa",
    expected: "DigitalOcean token value",
  },
  {
    name: "html entity github token",
    file: "browser.log",
    content: "github&#95;pat&#95;aaaaaaaaaaaaaaaaaaaaaaaa",
    expected: "GitHub fine-grained token value",
  },
  {
    name: "base64 encoded token",
    file: "evidence.json",
    content: Buffer.from("dop_v1_aaaaaaaaaaaaaaaa").toString("base64"),
    expected: "DigitalOcean token value",
  },
];

try {
  await assertBenignArtifactTreePasses();

  for (const testCase of forbiddenCases) {
    await assertForbiddenCaseFails(testCase);
  }

  await assertSymlinkFails();

  console.error("preview artifact safety fixture tests passed");
} finally {
  await fs.rm(tmpDir, { force: true, recursive: true });
}

async function assertBenignArtifactTreePasses() {
  const root = path.join(tmpDir, "benign");

  await writeFile(
    path.join(root, "deploy-receipt.json"),
    JSON.stringify(
      {
        outcome: "reviewable",
        failure: null,
        preview_url: previewUrl,
        checks: {
          runtime_viability: { status: "pass" },
          preview_page_acceptance: { status: "pass" },
        },
      },
      null,
      2,
    ),
  );
  await writeFile(
    path.join(root, "terminal.txt"),
    "preview URL      see deploy-receipt.json artifact\n",
  );
  await writeFile(
    path.join(root, "github-summary.md"),
    "| preview URL | see deploy-receipt.json artifact |\n",
  );
  await writeFile(
    path.join(root, "stages/preview-page-acceptance/network.json"),
    JSON.stringify({
      responses: [{ url: `${previewUrl}/en/note/prod-build-smoke-note` }],
    }),
  );

  const findings = await scanArtifactTree(root);
  assertEqual(findings.length, 0, "benign artifact finding count");
}

async function assertForbiddenCaseFails(testCase) {
  const root = path.join(tmpDir, slugify(testCase.name));

  await writeFile(
    path.join(root, "deploy-receipt.json"),
    JSON.stringify({ outcome: "blocked", failure: { stage: "fixture" } }),
  );
  await writeFile(path.join(root, testCase.file), testCase.content);

  const findings = await scanArtifactTree(root);

  if (!findings.some((finding) => finding.reason === testCase.expected)) {
    throw new Error(
      [
        `${testCase.name}: expected finding ${JSON.stringify(testCase.expected)}`,
        `observed findings: ${JSON.stringify(findings, null, 2)}`,
      ].join("\n"),
    );
  }
}

async function assertSymlinkFails() {
  const root = path.join(tmpDir, "symlink");
  const outside = path.join(tmpDir, "outside-token.txt");
  const symlink = path.join(root, "stages/runtime-viability/token-link");

  await writeFile(
    path.join(root, "deploy-receipt.json"),
    JSON.stringify({ outcome: "blocked", failure: { stage: "fixture" } }),
  );
  await writeFile(outside, "DIGITALOCEAN_TOKEN=dop_v1_hidden");
  await fs.mkdir(path.dirname(symlink), { recursive: true });
  await fs.symlink(outside, symlink);

  const findings = await scanArtifactTree(root);

  if (!findings.some((finding) => finding.reason === "symbolic link")) {
    throw new Error(
      `symlink: expected symbolic link finding, got ${JSON.stringify(findings, null, 2)}`,
    );
  }
}

async function writeFile(filePath, content) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, `${content}\n`);
}

function slugify(name) {
  return name.replaceAll(/[^a-z0-9]+/g, "-").replaceAll(/^-|-$/g, "");
}

function assertEqual(observed, expected, label) {
  if (observed !== expected) {
    throw new Error(
      `${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(observed)}`,
    );
  }
}
