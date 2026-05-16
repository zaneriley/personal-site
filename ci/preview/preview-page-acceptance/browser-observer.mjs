import path from "node:path";
import { devices } from "playwright";
import { FailureCode, makeFailure } from "./failure-catalog.mjs";

const DOM_ABSOLUTE_URL_CHECKS = [
  { name: "canonical", selector: 'link[rel="canonical"]', attr: "href" },
  { name: "og:url", selector: 'meta[property="og:url"]', attr: "content" },
  { name: "og:image", selector: 'meta[property="og:image"]', attr: "content" },
  {
    name: "twitter:image",
    selector: 'meta[name="twitter:image"]',
    attr: "content",
  },
];

const SHARE_METADATA_SELECTORS = {
  "og:title": 'meta[property="og:title"]',
  "og:description": 'meta[property="og:description"]',
  "og:url": 'meta[property="og:url"]',
  "og:image": 'meta[property="og:image"]',
  "twitter:card": 'meta[name="twitter:card"]',
  "twitter:title": 'meta[name="twitter:title"]',
  "twitter:description": 'meta[name="twitter:description"]',
  "twitter:image": 'meta[name="twitter:image"]',
};

export async function observeRouteViewport({
  browser,
  route,
  viewport,
  previewFetchOrigin,
  screenshotsDir,
}) {
  const pageErrors = [];
  const consoleErrors = [];
  const requestFailures = [];
  const wrongOriginResponses = [];
  const badResponseStatuses = [];
  const exerciseFailures = [];
  const liveWebSockets = [];
  const context = await browser.newContext({
    ...contextOptions(viewport),
    serviceWorkers: "block",
  });

  let page;
  let mainResponse = null;
  let screenshot = null;
  let bodyText = "";
  let html = "";
  let cspViolations = [];
  let documentAbsoluteUrls = [];
  let documentMetadata = {};
  let requiredDomState = [];
  let clientState = {
    appJsLoaded: false,
    liveSocketPresent: false,
    liveViewConnected: false,
  };
  let layoutState = {
    bodyTextLength: 0,
    viewportWidth: 0,
    documentScrollWidth: 0,
  };

  try {
    await installCspObserver(context);
    page = await context.newPage();
    observePageEvents(page, {
      pageErrors,
      consoleErrors,
      requestFailures,
      wrongOriginResponses,
      badResponseStatuses,
      liveWebSockets,
      previewFetchOrigin,
    });

    try {
      mainResponse = await exerciseRoutePage(page, route);
    } catch (error) {
      mainResponse = error.mainResponse ?? mainResponse;
      exerciseFailures.push(
        makeFailure(route.label, viewport.label, FailureCode.BROWSER_CHECK_EXCEPTION, {
          message: error.message,
        }),
      );
    }

    screenshot = await captureScreenshot({
      page,
      route,
      viewport,
      screenshotsDir,
      exerciseFailures,
    });

    try {
      const snapshot = await collectPageSnapshot(page, route);
      bodyText = snapshot.bodyText;
      html = snapshot.html;
      cspViolations = snapshot.cspViolations;
      documentAbsoluteUrls = snapshot.documentAbsoluteUrls;
      documentMetadata = snapshot.documentMetadata;
      requiredDomState = snapshot.requiredDomState;
      clientState = {
        ...snapshot.clientState,
        liveWebSocketSeen: liveWebSockets.length > 0,
      };
      layoutState = snapshot.layoutState;
    } catch (error) {
      exerciseFailures.push(
        makeFailure(route.label, viewport.label, FailureCode.BROWSER_CHECK_EXCEPTION, {
          message: error.message,
          phase: "collect_page_snapshot",
        }),
      );
    }
  } finally {
    await context.close();
  }

  return {
    label: viewport.label,
    status: mainResponse?.status() ?? null,
    bodyText,
    html,
    screenshot,
    exerciseFailures,
    pageErrors,
    consoleErrors,
    requestFailures,
    wrongOriginResponses,
    badResponseStatuses,
    cspViolations,
    documentAbsoluteUrls,
    documentMetadata,
    requiredDomState,
    clientState,
    layoutState,
  };
}

async function installCspObserver(context) {
  await context.addInitScript(() => {
    window.__previewCspViolations = [];
    document.addEventListener("securitypolicyviolation", (event) => {
      window.__previewCspViolations.push({
        blocked_uri: event.blockedURI,
        violated_directive: event.violatedDirective,
        effective_directive: event.effectiveDirective,
        source_file: event.sourceFile,
        line_number: event.lineNumber,
      });
    });
  });
}

function observePageEvents(page, observations) {
  page.on("pageerror", (error) => {
    observations.pageErrors.push(error.message);
  });
  page.on("console", (message) => {
    if (message.type() === "error") {
      observations.consoleErrors.push(message.text());
    }
  });
  page.on("requestfailed", (request) => {
    observations.requestFailures.push({
      url: request.url(),
      resource_type: request.resourceType(),
      failure: request.failure()?.errorText ?? "unknown",
    });
  });
  page.on("response", (response) => {
    const parsedUrl = parseHttpUrl(response.url());

    if (
      parsedUrl !== null &&
      parsedUrl.origin !== observations.previewFetchOrigin
    ) {
      observations.wrongOriginResponses.push({
        url: response.url(),
        origin: parsedUrl.origin,
        allowed_origins: [observations.previewFetchOrigin],
      });
    }

    if (parsedUrl !== null && response.status() >= 400) {
      observations.badResponseStatuses.push({
        url: response.url(),
        status: response.status(),
      });
    }
  });
  page.on("websocket", (websocket) => {
    const parsedUrl = parseHttpUrl(websocket.url().replace(/^ws/i, "http"));

    if (
      parsedUrl !== null &&
      parsedUrl.origin === observations.previewFetchOrigin &&
      parsedUrl.pathname.endsWith("/live/websocket")
    ) {
      observations.liveWebSockets.push(true);
    }
  });
}

async function exerciseRoutePage(page, route) {
  const mainResponse = await page.goto(route.routeUrl, {
    waitUntil: "domcontentloaded",
    timeout: 20_000,
  });

  try {
    await page.waitForLoadState("load", { timeout: 10_000 }).catch(() => {});

    for (const selector of route.requiredDom) {
      await page
        .locator(selector)
        .first()
        .waitFor({
          state: "visible",
          timeout: 5_000,
        })
        .catch(() => {});
    }

    for (const text of route.requiredVisibleText) {
      await page
        .getByText(text, { exact: false })
        .first()
        .waitFor({
          state: "visible",
          timeout: 5_000,
        })
        .catch(() => {});
    }

    if (route.requireLiveView) {
      await page
        .waitForFunction(
          () => Boolean(window.liveSocket?.isConnected?.()),
          undefined,
          { timeout: 5_000 },
        )
        .catch(() => {});
    }

    await page.waitForTimeout(250);
  } catch (error) {
    error.mainResponse = mainResponse;
    throw error;
  }

  return mainResponse;
}

async function captureScreenshot({
  page,
  route,
  viewport,
  screenshotsDir,
  exerciseFailures,
}) {
  if (route.screenshot === false) {
    return null;
  }

  const screenshotPath = path.join(
    screenshotsDir,
    `${safeFilename(route.label)}-${safeFilename(viewport.label)}.png`,
  );

  await page
    .screenshot({ path: screenshotPath, fullPage: true })
    .catch((error) => {
      exerciseFailures.push(
        makeFailure(route.label, viewport.label, FailureCode.SCREENSHOT_FAILED, {
          message: error.message,
        }),
      );
    });

  return screenshotPath;
}

async function collectPageSnapshot(page, route) {
  return {
    bodyText: await page.locator("body").innerText({ timeout: 5_000 }),
    html: await page.content(),
    cspViolations: await page.evaluate(
      () => window.__previewCspViolations ?? [],
    ),
    documentAbsoluteUrls: await collectDocumentAbsoluteUrls(page),
    documentMetadata: await collectDocumentMetadata(page),
    requiredDomState: await collectRequiredDomState(page, route.requiredDom),
    clientState: await collectClientState(page),
    layoutState: await collectLayoutState(page),
  };
}

async function collectRequiredDomState(page, selectors) {
  return page.evaluate((requiredSelectors) => {
    return requiredSelectors.map((selector) => {
      const element = document.querySelector(selector);

      if (element === null) {
        return { selector, visible: false, reason: "missing" };
      }

      const rect = element.getBoundingClientRect();
      const style = window.getComputedStyle(element);
      const visible =
        rect.width > 0 &&
        rect.height > 0 &&
        style.display !== "none" &&
        style.visibility !== "hidden";

      return { selector, visible, reason: visible ? null : "not_visible" };
    });
  }, selectors);
}

async function collectDocumentAbsoluteUrls(page) {
  return page.evaluate((checks) => {
    return checks.flatMap((check) =>
      Array.from(document.querySelectorAll(check.selector)).map((element) => ({
        ...check,
        value: element.getAttribute(check.attr),
      })),
    );
  }, DOM_ABSOLUTE_URL_CHECKS);
}

async function collectDocumentMetadata(page) {
  return page.evaluate((selectors) => {
    return Object.fromEntries(
      Object.entries(selectors).map(([name, selector]) => [
        name,
        document.querySelector(selector)?.getAttribute("content"),
      ]),
    );
  }, SHARE_METADATA_SELECTORS);
}

async function collectClientState(page) {
  return page.evaluate(() => ({
    appJsLoaded: Boolean(window.liveSocket),
    liveSocketPresent: Boolean(window.liveSocket),
    liveViewConnected: Boolean(window.liveSocket?.isConnected?.()),
    liveWebSocketSeen: false,
  }));
}

async function collectLayoutState(page) {
  return page.evaluate(() => ({
    bodyTextLength: document.body.innerText.trim().length,
    viewportWidth: window.innerWidth,
    documentScrollWidth: document.documentElement.scrollWidth,
  }));
}

function contextOptions(viewport) {
  if (viewport.device !== undefined) {
    const device = devices[viewport.device];

    if (device === undefined) {
      throw new Error(`unknown Playwright device: ${viewport.device}`);
    }

    return device;
  }

  return {
    viewport: {
      width: viewport.width,
      height: viewport.height,
    },
  };
}

function parseHttpUrl(rawUrl) {
  try {
    const parsedUrl = new URL(rawUrl);

    if (["http:", "https:"].includes(parsedUrl.protocol)) {
      return parsedUrl;
    }
  } catch {
    return null;
  }

  return null;
}

function safeFilename(value) {
  return value.replaceAll(/[^a-zA-Z0-9_-]/g, "-").replaceAll(/-+/g, "-");
}
