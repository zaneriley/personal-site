/**
 * React Static Boilerplate
 * https://github.com/kriasoft/react-static-boilerplate
 *
 * Copyright © 2015-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { PropTypes } from 'react';
import Layout from '../../../components/Layout';
import Link from '../../../components/Link';
import s from './styles.css';
import g from '../../styles/grid.css';
import v from '../../styles/aesthetics.css';
import { title, html } from './index.md';

class HomePage extends React.Component {

  static propTypes = {
  };

  componentDidMount() {
    document.title = title;
  }

  render() {
    return (
      <Layout className={` ${g.maxWidth} `}>
        <div dangerouslySetInnerHTML={{ __html: html }} className={`${g.g9m} ${g.g6l}`}/>
        <p className={`${g.g9m} ${g.g6l}`}><Link className="mdl-navigation__link" to="/case-study/improving-purchase-process">Improving the purchase process of Classes and Kits</Link></p>
        <p className={`${g.g9m} ${g.g6l}`}><Link className="mdl-navigation__link" to="/case-study/building-a-design-system">Building a Design system.</Link></p>
      </Layout>
    );
  }

}

export default HomePage;
