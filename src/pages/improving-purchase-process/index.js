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
import v from '../../styles/aesthetics.css';
import { title, about, html } from './index.md';

/* Images for this Page */
import before from '../../assets/images/kit-pdp-desktop-before@2x.jpg';
import after from '../../assets/images/kit-pdp-desktop-after@2x.jpg';
import purchaseFlowOfClass from '../../assets/images/purchase-flow-class-draft.svg'
import wireframeKit from '../../assets/images/kit-wireframe.svg'
import calloutPanel from '../../assets/images/callout-panel.svg'

class ImprovingPurchaseProcessPage extends React.Component {

  componentDidMount() {
    document.title = title;
  }

  render() {
    return (
      <Layout className={s.content}>

        <About title={title} about="Brit + Co helps women discover online courses and DIY tutorials to improve their creativity and embrace their passion. At the time of this project, we separately sold the supplies (“Kits”) for projects and Classes." role="Wireframing and visual design of kit page. Developed prototype and led user testing." result="<strong>3.5% increase</strong> in the attach rate (the rate at which classes and kits were purchased together)."/>

        <ImageCompare before={before} after={after} className={`${g.gMarginTopLarge}`}/>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <p className={`${g.g6l} ${v.dropCap}`}>I was asked to increase the attach rate between  Brit + Co’s two main products – Classes, offering instruction on topics like calligraphy, and Kits, supplies for both projects <span className={`${g.noWrap}`}>and Classes.</span></p>

          <p className={`${g.g6l}`}>When measuring the attach rate, it’s usually clear which product is primary and which is secondary. For example, if we were selling smart phones, it would be the primary product. Phone accessories, like cases, would be secondary. For Classes and Kits, however, the primary product wasn’t quite <span className={`${g.noWrap}`}>so obvious.</span></p>

          <p className={`${g.g6l}`}>To increase the attach rate, we first had to understand which of our products was primary, and which one <span className={`${g.noWrap}`}>was secondary.</span></p>

          <p className={`${g.g6l}`}>The relationship between specific Classes and Kits varied wildly. Some products worked together seamlessly, like the Calligraphy Class and Calligraphy Kit. Other pairings were less straightforward. Some classes had no kit, and some kits had no <span className={`${g.noWrap}`}>matching class.</span></p>

          <div className={`${g.g8l} ${g.gMarginTopSmall}`}>
            <blockquote className={`${g.g6m} ${g.floatRightM}`}>To increase the attach rate, we first had to understand which of our products was primary, and which one was secondary.</blockquote>

            <p className={`${g.g6l}`}>We couldn’t lock ourselves into a single pricing strategy while the company was exploring product/market fit. We would need to increase the attach rate without simplifying pricing or changing products.</p>

            <p className={`${g.g6l}`}>One interesting piece of data helped shape our solution:</p> 
          </div>

          <figure className={`${g.gMarginTopLarge}`}>
          <h3>Purchase Flow of Classes</h3>
          <img src={purchaseFlowOfClass} />
          </figure>

          <figure className={`${g.gMarginTopLarge}`}>
          <h3>Purchase Flow of Kits</h3>
          <img src={purchaseFlowOfClass} />
          </figure>

          <p className={`${g.g6l} ${g.gMarginTopLarge}`}>Users viewing Classes were likely to view and purchase Kits, but users viewing Kits were not likely to view or purchase Classes.</p>

          <p className={`${g.g6l}`}>People seeking Kits may not need or want instruction; they could simply want supplies for their projects. People interested in Classes, on the other hand, seemed to also want all the supplies they need to begin learning that craft. We needed to make it easier for those viewing Classes to purchase related Kits, and we needed to convince those looking at Kits to view Classes as well.</p>

        </div>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
            <div className={`${g.gPositionAbsoluteL} ${g.right} ${g.g4l}`}>
              <h3>Kit Page Wireframe</h3>
              <p>On kit pages that had a matching class, we added a callout that encouraged users to click through to the class. Messaging was positioned around making sure a user’s project turned out well.</p>
            </div>
          <figure className={`${s.flexContainer}`}>
            <img src={wireframeKit} className={`${g.g7m} ${v.shadow1}`} />
            <img src={calloutPanel} className={`${g.g10s} ${g.g6m} ${v.shadow2} ${s.calloutPanel}`} />
          </figure>
        </div>
        <div dangerouslySetInnerHTML={{ __html: html }} />
      </Layout>
    );
  }

}

export default ImprovingPurchaseProcessPage;
