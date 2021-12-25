import React, { Fragment } from "react";
import GlobalStyle from "../components/globalStyles";

function App({ Component, pageProps }) {
  return (
    <Fragment>
      <GlobalStyle />
      <Component {...pageProps} />
    </Fragment>
  );
}

export default App;
