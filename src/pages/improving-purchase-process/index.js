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
import Video from 'react-html5video';
import s from './styles.css';
import g from '../../styles/grid.css';
import v from '../../styles/aesthetics.css';
import { title, html } from './index.md';

/* Images for this Page */
import before from '../../assets/images/kit-pdp-desktop-before@2x.jpg';
import after from '../../assets/images/kit-pdp-desktop-after@2x.jpg';

import purchaseFlowOfClass from '../../assets/images/purchase-flow-class-draft.svg';

import wireframeKit from '../../assets/images/kit-wireframe.svg';
import calloutPanel from '../../assets/images/callout-panel.svg';

import wireframeClass from '../../assets/images/class-wireframe.svg';
import addToCartPanel from '../../assets/images/add-to-cart.svg';

import userTestWebm from '../../assets/images/user-test.webm';
import userTestMp4 from '../../assets/images/user-test.mp4';

class ImprovingPurchaseProcessPage extends React.Component {

  componentDidMount() {
    document.title = title;
  }

  render() {
    return (
      <Layout className={s.content}>

        <About title={title} about="Brit + Co helps women discover online courses and DIY tutorials to improve their creativity and embrace their passion. At the time of this project, we separately sold the supplies (“Kits”) for projects and Classes." role="Wireframing and visual design of kit page. Developed prototype and led user testing." result="<strong>3.5% increase</strong> in the attach rate (how often classes and kits were purchased together)."/>

        <ImageCompare before={before} after={after} className={`${g.gMarginTopLarge}`}/>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <p className={`${g.g6l} ${v.dropCap}`}>I was asked to increase the attach rate between  Brit + Co’s two main products – Classes, offering instruction on topics like calligraphy, and Kits, supplies for both projects <span className={`${g.noWrap}`}>and Classes.</span></p>

          <p className={`${g.g6l}`}>When measuring the attach rate, it’s usually clear which product is primary and which is secondary. For example, if we were selling smart phones, it would be the primary product. Phone accessories, like cases, would be secondary. For Classes and Kits, however, the primary product wasn’t quite <span className={`${g.noWrap}`}>so obvious.</span></p>

          <p className={`${g.g6l}`}>To increase the attach rate, we first had to understand which of our products was primary, and which one <span className={`${g.noWrap}`}>was secondary.</span></p>

          <p className={`${g.g6l}`}>The relationship between specific Classes and Kits varied wildly. Some products worked together seamlessly, like the Calligraphy Class and Calligraphy Kit. Other pairings were less straightforward. Some classes had no kit, and some kits had no <span className={`${g.noWrap}`}>matching class.</span></p>

          <div className={`${g.gMarginTopSmall} ${g.gFlexContainer} ${g.gNoFlexWrap} `}>
            <div className={`${g.g4l}`}>
            <p>We couldn’t lock ourselves into a single pricing strategy while the company was exploring product/market fit. We would need to increase the attach rate without simplifying pricing or changing products.</p>

            <p>One interesting piece of data helped shape our solution:</p>
            </div>
            <blockquote className={`${g.g4l} ${g.gNoMarginTopS}`}>To increase the attach rate, we first had to understand which of our products was primary, and which one was secondary.
            </blockquote>
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

        <div className={`${g.maxWidth} ${g.gMarginTopLarge} ${g.gFlexContainer} ${g.gFlexEnd} ${s.kitWrapper}`}>
            <div className={`${g.right} ${g.g4l} ${s.aboutKit}`}>
              <h3>Kit Page Wireframe</h3>
              <p>On kit pages that had a matching class, we added a callout that encouraged users to click through to the class. Messaging was positioned around making sure a user’s project turned out well.</p>
            </div>
          <figure className={`${s.wireframeKit} ${g.g8m} ${g.g7l} ${v.shadow1}`} >
            <img src={wireframeKit} />
          </figure>
          <figure className={`${s.calloutPanel} ${g.g7m} ${v.shadow2}`}>
             <img src={calloutPanel} />
          </figure>
        </div>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge} ${g.gFlexContainer} ${g.gFlexStart} ${s.classWrapper}`}>
            <div className={`${g.right} ${g.g4l}`}>
              <h3>Class Page Wireframe</h3>
              <p>Krystle Cho, a product designer, mocked up a solution that allowed users to purchase both kits and classes.</p>
              <p>On both pages, we removed all content from the right rail so that only the add-to-cart module remained.</p>
            </div>
          <figure className={`${s.wireframeClass} ${g.g8m} ${g.g7l} ${v.shadow1}`} >
            <img src={wireframeClass} />
          </figure>
          <figure className={`${s.addToCartPanel} ${g.g6m} ${g.g4l} ${g.gAlignSelfEnd} ${v.shadow2}`}>
             <img src={addToCartPanel} />
          </figure>
        </div>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge} ${g.gFlexContainer} ${g.gFlexEnd} ${s.userTestingWrapper}`}>
            <div className={`${g.g6l} ${g.gFlexStart} ${g.gAlignSelfStart} ${s.aboutUserTesting}`}>
              <h3>User Testing</h3>
              <p> This was a clear direction, but we still needed to validate it with users, so I conducted a round of in-person user tests with 5 people.</p>
              <p>The results showed we still needed to communicate our pricing structure more effectively. For instance, in the first user test below, Sophie couldn't understand the price range until she selected the drop down menu.</p>
            </div>
            <blockquote className={`${g.g4l} ${s.userQuote}`}>“Okay, Class and Kit… well that’s confusing, because it looks like it’s a price range, not a choice.”
            </blockquote>
            <video className={`${g.g6l}`} controls autoPlay loop muted poster="http://placehold.it/20x20/">
              <source src={userTestWebm} type="video/webm" />
              <source src={userTestMp4} type="video/mp4" />
            </video>
        </div>

      </Layout>
    );
  }

}

export default ImprovingPurchaseProcessPage;
