import Document, { Html, Head, Main, NextScript } from "next/document";
import { ServerStyleSheet } from "styled-components";

export default class MyDocument extends Document {
  static async getInitialProps(ctx) {
    const sheet = new ServerStyleSheet();
    const originalRenderPage = ctx.renderPage;

    try {
      ctx.renderPage = () =>
        originalRenderPage({
          enhanceApp: (App) => (props) =>
            sheet.collectStyles(<App {...props} />),
        });

      const initialProps = await Document.getInitialProps(ctx);
      return {
        ...initialProps,
        styles: (
          <>
            {initialProps.styles}
            {sheet.getStyleElement()}
          </>
        ),
      };
    } finally {
      sheet.seal();
    }
  }
  render() {
    return (
      <Html>
        <Head>
          <link
            rel="icon"
            type="image/svg+xml"
            href="/images/favicon/favicon.svg"
          />
          <link
            rel="icon"
            type="image/png"
            href="/images/favicon/favicon.png"
          />
          <link
            rel="preload"
            href="fonts/GT-Flexa-Standard-Regular.woff2"
            as="font"
            type="font/woff2"
            crossOrigin="true"
          />{" "}
          <meta name="twitter:card" content="summary_large_image" />
          <meta name="twitter:site" content="@zaneriley" />
          <meta name="twitter:creator" content="@zaneriley" />
          <meta
            name="twitter:title"
            content="Zane Riley's product design portfolio"
          />
          <meta
            name="twitter:description"
            content="Zane Riley is a product designer based out of Tokyo and San Francisco"
          />
          <meta
            name="twitter:image"
            content="https://zaneriley.com/public/assets/social-twitter.jpg"
          />
        </Head>
        <body>
          <Main />
          <NextScript />
        </body>
      </Html>
    );
  }
}
