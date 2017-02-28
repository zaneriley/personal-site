/**
 * React Static Boilerplate
 * https://github.com/kriasoft/react-static-boilerplate
 *
 * Copyright © 2015-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import Logo from '../Logo';
import Navigation from '../Navigation';
import Link from '../Link';
import s from './Header.css';
import g from '../../src/styles/grid.css';

class Header extends React.Component {

  componentDidMount() {
    window.componentHandler.upgradeElement(this.root);
  }

  componentWillUnmount() {
    window.componentHandler.downgradeElements(this.root);
  }

  render() {
    return (
      <header ref={node => (this.root = node)}>
        <Logo className={`${s.logo}`}/>
      </header>
    );
  }

}

export default Header;
