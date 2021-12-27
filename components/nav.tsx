import React, { Fragment } from "react";
import { Grid } from "./grid";
import Link from "next/Link";
import Logo from "./logo";

class Nav extends React.Component {

  render() {
    return <Grid><Link href="/"><a><Logo /></a></Link></Grid>;
  }
};

export default Nav;