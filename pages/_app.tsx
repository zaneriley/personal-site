import React, { Fragment } from "react";
import GlobalStyle from "../components/globalStyles";
import Nav from "../components/nav";

function App({ Component, pageProps }) {
  return (
    <Fragment>
      <GlobalStyle />
      <Nav />
      <Component {...pageProps} />
    </Fragment>
  );
}

export default App;
