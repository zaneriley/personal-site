import Document, { Html, Head, Main, NextScript } from 'next/document'

class MyDocument extends Document {
  static async getInitialProps(ctx) {
    const initialProps = await Document.getInitialProps(ctx)
    return { ...initialProps }
  }

  render() {
    return (
      <Html>
        <Head>
          <link rel="icon" type="image/svg+xml" href="/images/favicon/favicon.svg" />
          <link rel="icon" type="image/png" href="/images/favicon/favicon.png" />

          <meta name="twitter:card" content="summary_large_image" />
          <meta name="twitter:site" content="@zaneriley" />
          <meta name="twitter:creator" content="@zaneriley" />
          <meta name="twitter:title" content="Zane Riley's product design portfolio" />
          <meta name="twitter:description" content="Zane Riley is a product designer based out of Tokyo and San Francisco" />
          <meta name="twitter:image" content="https://zaneriley.com/public/assets/social-twitter.jpg" />
        </Head>
        <body>
          <Main />
          <NextScript />
        </body>
      </Html>
    )
  }
}

export default MyDocument
