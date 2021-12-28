import React, { Component, Fragment } from "react";
import Router from 'next/router';
import GlobalStyle from "../components/globalStyles";
import Nav from "../components/nav";

export default class App extends React.Component {

  static async getInitialProps({ Component, router, ctx }) {
    let pageProps = {}

    if (Component.getInitialProps) {
      pageProps = await Component.getInitialProps(ctx)
    }

    return { pageProps }
  }
    
  constructor(props) {
    super(props)

    this.logos = ['kana', 'signature', 'alphabet'],
    this.state = {
      currentLogo: this.logos[Math.floor(Math.random() * this.logos.length)],
    }

    Router.onRouteChangeStart = (url) => {
      let logoset = new Set(this.logos);
      logoset.delete(this.state.currentLogo);

      this.setState({
        currentLogo: Array.from(logoset)[Math.floor(Math.random() * logoset.size)]
      })
    };
  
    // Router.onRouteChangeComplete = (url) => {
    //   // Some page has finished loading
    //   // Set state to pass to loader props
    // };
  
    // Router.onRouteChangeError = (err, url) => {
    //   // an error occurred.
    //   // some custom error logic.
    // };
  
  };
  
  render() { 
    const { Component, pageProps } = this.props
    
    return (
      <Fragment>
        <GlobalStyle />
        <Nav logo={this.state.currentLogo}/>
        <Component {...pageProps} />
      </Fragment>
    );
  } 
}
