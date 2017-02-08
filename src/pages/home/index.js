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
import { title, html } from './index.md';

class HomePage extends React.Component {

  static propTypes = {
  };

  componentDidMount() {
    document.title = title;
  }

  render() {
    return (
      <Layout className={s.content}>
        <div dangerouslySetInnerHTML={{ __html: html }} />
        <p>I can add more stuff using the index.js file if I need to.
        <Link className="mdl-navigation__link" to="/case-study/improving-purchase-process">Improving the purchase process of Classes and Kits</Link></p>
      </Layout>
    );
  }

}

export default HomePage;
