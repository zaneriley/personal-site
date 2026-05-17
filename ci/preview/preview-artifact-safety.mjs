#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";

if (import.meta.url === `file://${process.argv[1]}`) {
  const root = process.argv[2];

  if (root === undefined || root.trim() === "") {
    console.error("Usage: preview-artifact-safety.mjs .tmp/ci-artifacts/preview");
    process.exit(64);
  }

  const findings = await scanArtifactTree(root);

  if (findings.length > 0) {
    console.error("preview artifact safety check failed");
    for (const finding of findings) {
      console.error(`- ${finding.file}: ${finding.reason}`);
    }
    process.exit(1);
  }

  console.error("preview artifact safety check passed");
}

export async function scanArtifactTree(root) {
  const files = await listFiles(root);
  const findings = [];

  for (const file of files) {
    const filePath = file.path;
    const relativePath = path.relative(root, filePath);
    const normalizedPath = relativePath.split(path.sep).join("/");

    if (file.unsafeEntry !== null) {
      findings.push({ file: normalizedPath, reason: file.unsafeEntry });
      continue;
    }

    for (const forbiddenPath of [".registry-auth.env", ".registry-token"]) {
      if (normalizedPath.split("/").includes(forbiddenPath)) {
        findings.push({ file: normalizedPath, reason: forbiddenPath });
      }
    }

    const content = await fs.readFile(filePath, "utf8");
    findings.push(...scanText(normalizedPath, content));
  }

  return findings;
}

async function listFiles(root) {
  const entries = await fs.readdir(root, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const entryPath = path.join(root, entry.name);
    const stat = await fs.lstat(entryPath);

    if (stat.isSymbolicLink()) {
      files.push({ path: entryPath, unsafeEntry: "symbolic link" });
    } else if (entry.isDirectory()) {
      files.push(...(await listFiles(entryPath)));
    } else if (entry.isFile()) {
      files.push({ path: entryPath, unsafeEntry: null });
    } else {
      files.push({ path: entryPath, unsafeEntry: "non-regular file" });
    }
  }

  return files;
}

function scanText(filePath, content) {
  const findings = [];
  const searchableContent = normalizedTextVariants(content).join("\n");
  const forbiddenMarkers = [
    "DIGITALOCEAN_TOKEN",
    "DEPLOY_SSH_PRIVATE_KEY",
    "DEPLOY_SSH_PUBLIC_KEY",
    "SECRET_KEY_BASE=",
    "POSTGRES_PASSWORD=",
    "GITHUB_WEBHOOK_SECRET=",
    "RUNTIME_VIABILITY_REGISTRY_TOKEN",
    "auths",
  ];

  for (const marker of forbiddenMarkers) {
    if (searchableContent.includes(marker)) {
      findings.push({ file: filePath, reason: marker });
    }
  }

  for (const rule of valuePatternRules()) {
    if (rule.pattern.test(searchableContent)) {
      findings.push({ file: filePath, reason: rule.reason });
    }
  }

  findings.push(...decodedDockerAuthFindings(filePath, content));

  if (isPublicTextSurface(filePath) && publicPreviewUrlPattern().test(searchableContent)) {
    findings.push({ file: filePath, reason: "public preview URL" });
  }

  return findings;
}

function normalizedTextVariants(content) {
  const variants = new Set([content]);
  const percentDecoded = decodePercent(content);
  variants.add(percentDecoded);
  variants.add(decodeHtmlEntities(percentDecoded));
  variants.add(decodeJsonUnicodeEscapes(percentDecoded));

  for (const match of content.matchAll(/\b[A-Za-z0-9+/]{20,}={0,2}\b/g)) {
    try {
      const decoded = Buffer.from(match[0], "base64").toString("utf8");
      if (/^[\t\n\r -~]+$/.test(decoded)) {
        variants.add(decoded);
      }
    } catch {
      // Ignore malformed base64-like text; raw content is still scanned.
    }
  }

  return Array.from(variants);
}

function decodePercent(content) {
  try {
    return decodeURIComponent(content);
  } catch {
    return content.replaceAll(/%([0-9a-fA-F]{2})/g, (_, hex) =>
      String.fromCharCode(Number.parseInt(hex, 16)),
    );
  }
}

function decodeHtmlEntities(content) {
  return content
    .replaceAll(/&#95;|&#x5f;|&lowbar;/gi, "_")
    .replaceAll(/&colon;/gi, ":");
}

function decodeJsonUnicodeEscapes(content) {
  return content.replaceAll(/\\u([0-9a-fA-F]{4})/g, (_, hex) =>
    String.fromCharCode(Number.parseInt(hex, 16)),
  );
}

function valuePatternRules() {
  return [
    { reason: "DigitalOcean token value", pattern: /\bdop_v1_[A-Za-z0-9_-]{8,}/ },
    { reason: "GitHub token value", pattern: /\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{20,}/ },
    { reason: "GitHub fine-grained token value", pattern: /\bgithub_pat_[A-Za-z0-9_]{20,}/ },
    { reason: "OpenSSH private key", pattern: /-----BEGIN OPENSSH PRIVATE KEY-----/ },
    { reason: "Bearer auth header", pattern: /\bAuthorization:\s*Bearer\s+\S+/i },
    { reason: "Basic auth header", pattern: /\bAuthorization:\s*Basic\s+[A-Za-z0-9+/=]{12,}/i },
    { reason: "x-access-token credential", pattern: /\bx-access-token[:=]\S+/i },
  ];
}

function decodedDockerAuthFindings(filePath, content) {
  const findings = [];

  for (const match of content.matchAll(/"auth"\s*:\s*"([A-Za-z0-9+/=]{12,})"/g)) {
    findings.push({ file: filePath, reason: "docker auth value" });

    try {
      const decoded = Buffer.from(match[1], "base64").toString("utf8");
      for (const rule of valuePatternRules()) {
        if (rule.pattern.test(decoded)) {
          findings.push({ file: filePath, reason: `decoded ${rule.reason}` });
        }
      }
    } catch {
      // If it looks like auth but cannot decode, the raw value is still unsafe.
    }
  }

  return findings;
}

function isPublicTextSurface(filePath) {
  return /\.(?:md|txt|log)$/.test(filePath);
}

function publicPreviewUrlPattern() {
  return /http:\/\/(?:\d{1,3}\.){3}\d{1,3}:\d{2,5}\b/;
}
