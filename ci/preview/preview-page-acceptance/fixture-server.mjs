import http from "node:http";

export async function startPreviewFixtureServer(cases) {
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
  let fixtureOrigin = null;
  const fixturePages = new Map(cases.map((testCase) => [testCase.route, testCase]));
  const fixtureServer = await startServer((request, response) => {
    respondToFixtureRequest(request, response, {
      externalOrigin,
      fixtureOrigin,
      fixturePages,
    });
  });

  fixtureOrigin = `http://127.0.0.1:${fixtureServer.port}`;

  return {
    origin: fixtureOrigin,
    close: async () => {
      await fixtureServer.close();
      await externalServer.close();
    },
  };
}

function respondToFixtureRequest(request, response, context) {
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

  const testCase = context.fixturePages.get(route);

  if (testCase === undefined) {
    response.writeHead(500, { "content-type": "text/plain" });
    response.end(`unknown fixture route: ${route}`);
    return;
  }

  sendHtml(response, fixtureHtml(testCase.page, context), testCase.page.headers);
}

function fixtureHtml(page, context) {
  const origin = context.fixtureOrigin;
  const ogUrl = page.ogUrl ?? `${origin}/pass`;
  const ogImage = page.ogImage ?? `${origin}/images/og-default.png`;
  const shareMetadata =
    page.shareMetadata === false
      ? ""
      : `
    <meta property="og:title" content="Fixture Title">
    <meta property="og:description" content="Fixture Description">
    <meta property="og:url" content="${escapeHtml(ogUrl)}">
    <meta property="og:image" content="${escapeHtml(ogImage)}">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="Fixture Title">
    <meta name="twitter:description" content="Fixture Description">
    <meta name="twitter:image" content="${escapeHtml(ogImage)}">`;
  const externalAsset = page.externalImage
    ? `<img src="${context.externalOrigin}/external.png" alt="">`
    : "";

  return `<!doctype html>
<html>
  <head>
    <title>Fixture</title>
    <link rel="stylesheet" href="/style.css">
    ${shareMetadata}
    ${page.head ?? ""}
  </head>
  <body>
    <main>${escapeHtml(page.body ?? "Ready Content")}${externalAsset}</main>
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
