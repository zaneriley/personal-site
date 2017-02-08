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
import Layout from '../../../components/Layout';
import About from '../../../components/About';
import ImageCompare from '../../../components/ImageCompare';
import s from './styles.css';
import g from '../../styles/grid.css';
import { title, about, html } from './index.md';

import before from '../../assets/images/kit-pdp-desktop-before@2x.jpg';
import after from '../../assets/images/kit-pdp-desktop-after@2x.jpg';

class ImprovingPurchaseProcessPage extends React.Component {

  componentDidMount() {
    document.title = title;
  }

  render() {
    return (
      <Layout className={s.content}>
        <About title={title} about="Brit + Co helps women discover online courses and DIY tutorials to improve their creativity and embrace their passion. At the time of this project, we separately sold the supplies (“Kits”) for projects and Classes." role="Wireframing and visual design of kit page. Developed prototype and led user testing." result="<strong>3.5% increase</strong> in the attach rate (the rate at which classes and kits were purchased together)."/>
        <ImageCompare before={before} after={after}/>
        <div dangerouslySetInnerHTML={{ __html: html }} />
      </Layout>
    );
  }

}

export default ImprovingPurchaseProcessPage;
