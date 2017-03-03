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
import recommendedPages from '../../relatedPages.json';
import Layout from '../../../components/Layout';
import About from '../../../components/About';
import Link from '../../../components/Link';
import LinkExternal from '../../../components/LinkExternal';
import HorizontalScroll from '../../../components/HorizontalScroll';
import ImageCompare from '../../../components/ImageCompare';
import Iphone from '../../../components/Iphone';
import UpNext from '../../../components/UpNext';
import s from './styles.css';
import g from '../../styles/grid.css';
import v from '../../styles/aesthetics.css';
import {title, html} from './index.md';

/* Images for this Page */
import before from '../../assets/images/kit-pdp-desktop-before@2x.jpg';
import after from '../../assets/images/kit-pdp-desktop-after@2x.jpg';

import flowAllClasses from '../../assets/images/flow-all-classes.svg';
import flowAllKits from '../../assets/images/flow-all-kits.svg';
import flowArrow from '../../assets/images/flow-arrow-right.svg';
import flowSingleClass from '../../assets/images/flow-single-class.svg';
import flowSingleKit from '../../assets/images/flow-single-Kit.svg';

import wireframeKit from '../../assets/images/kit-wireframe.svg';
import calloutPanel from '../../assets/images/callout-panel.svg';

import wireframeClass from '../../assets/images/class-wireframe.svg';
import addToCartPanel from '../../assets/images/add-to-cart.svg';

import userTestWebm from '../../assets/images/user-test.webm';
import userTestMp4 from '../../assets/images/user-test.mp4';

import iphoneImage from '../../assets/images/user-test-result@2x.jpg';

class ImprovingPurchaseProcessPage extends React.Component {

  static defaultProps = {
    title: recommendedPages[0].title,
    recommendedPageFirst: {title: ''},
    recommendedPageSecond: {}
  };
  
  componentDidMount() {
    document.title = recommendedPages[0].title + ' | Zane Riley';
  }

  render() {
    const {title, about, role, result, readingLength} = recommendedPages[0];

    return (
      <Layout className={`${g.gPaddingTopLarge}`} breadCrumbs="Case Study" recommendedPageFirst={recommendedPages[1]} recommendedPageSecond={recommendedPages[2]}>

        <About title={title} about={about} role={role} result={result} readingLength={readingLength}/>

        <figure className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <ImageCompare before={before} after={after}/>
          <figcaption>Before and after designs of the <span className={`${g.noWrap}`}>Kit page.</span></figcaption>
        </figure>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <p className={`${g.g9m} ${g.g6l} ${g.center} ${v.dropCap}`}>I was asked to increase the attach rate between  Brit + Co’s two main products – Classes, offering instruction on topics like calligraphy, and Kits, supplies for both projects <span className={`${g.noWrap}`}>and Classes.</span></p>

          <p className={`${g.g9m} ${g.g6l} ${g.center} `}>When measuring the attach rate, it’s usually clear which product is primary and which is secondary. For example, if we were selling smart phones, it would be the primary product. Phone accessories, like cases, would be secondary. For Classes and Kits, however, the primary product wasn’t quite <span className={`${g.noWrap}`}>so obvious.</span></p>

          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>To increase the attach rate, we first had to understand which of our products was primary, and which one <span className={`${g.noWrap}`}>was secondary.</span></p>

          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>The relationship between specific Classes and Kits varied wildly. Some products worked together seamlessly, like the Calligraphy Class and Calligraphy Kit. Other pairings were less straightforward. Some classes had no kit, and some kits had no <span className={`${g.noWrap}`}>matching class.</span></p>

          <blockquote className={`${g.g5l} ${g.center} ${g.floatRightM}`}>To increase the attach rate, we first had to understand which of our products was primary, and which one was secondary.
          </blockquote>

          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>We couldn’t lock ourselves into a single pricing strategy while the company was exploring product/market fit. We would need to increase the attach rate without simplifying pricing or changing products.</p>

          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>One interesting piece of data helped shape our solution: How users viewed each product.</p>
        </div>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <h2 className={`${g.g9m} ${g.g6l} ${g.center}`}>User Flows</h2>
          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>Users took different paths through the site depending on which product they were initially looking at. Take a look at the flow of</p>
        </div>

        <div className={`${g.maxWidth}`}>
          <h3 className={`${g.g9m} ${g.g6l} ${g.center}`}>How People View Classes</h3>
        </div>
        <figure className={`${g.gMarginTopSmall}`}>
          <HorizontalScroll>
            <div className={`${g.g3Max} ${g.textCenter} ${g.gNoMarginTop} ${g.gMarginLeftSmallest}`}>
              <p>All Classes</p>
              <div className={`${g.gMarginTopSmall} ${g.thrashPreventerSquare}`}>
                <img src={flowAllClasses} className={`${g.gPositionAbsolute}`} />
              </div>
            </div>
            <div className={`${g.textCenter} ${g.gMarginLeftSmallest}`}>
              <img src={flowArrow} />
            </div>
            <div className={`${g.g3Max} ${g.textCenter} ${g.gNoMarginTop} ${g.gMarginLeftSmallest}`}>
              <p>Single Class</p>
              <div className={`${g.gMarginTopSmall} ${g.thrashPreventerSquare}`}>
                <img src={flowSingleClass} className={`${g.gPositionAbsolute}`} />
              </div>
            </div>
            <div className={`${g.textCenter} ${g.gMarginLeftSmallest}`}>
              <img src={flowArrow} />
            </div>
            <div className={`${g.g3Max} ${g.textCenter} ${g.gNoMarginTop} ${g.gMarginLeftSmallest}`}>
              <p>Single Kit</p>
              <div className={`${g.gMarginTopSmall} ${g.thrashPreventerSquare}`}>
                <img src={flowSingleKit} className={`${g.gPositionAbsolute}`} />
              </div>
            </div>
            <div className={`${g.textCenter} ${g.gMarginLeftSmallest}`}>
              <img src={flowArrow} />
            </div>
            <div className={`${g.g3Max} ${g.textCenter} ${g.gNoMarginTop} ${g.gMarginLeftSmallest}`}>
              <p>Buys Kit</p>
              <div className={`${g.gMarginTopSmall} ${g.thrashPreventerSquare} ${s.overlayRed}`}>
                <img src={flowSingleKit} className={`${g.gPositionAbsolute}`} />
              </div>
            </div>
            <div className={`${g.textCenter} ${g.gMarginLeftSmallest}`}>
              <img src={flowArrow} />
            </div>
            <div className={`${g.g3Max} ${g.textCenter} ${g.gNoMarginTop} ${g.gMarginLeftSmaller}`}>
              <p>Buys Class</p>
              <div className={`${g.gMarginTopSmall} ${s.overlayBlue} ${g.thrashPreventerSquare} `} >
                <img src={flowSingleClass} className={`${g.gPositionAbsolute}`} />
              </div>
            </div>
          </HorizontalScroll>
        </figure>

        <div className={`${g.maxWidth}`}>
          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>Users viewing Classes were likely to view and purchase Kits, but users viewing Kits were not likely to view or purchase Classes. They were unlikely to look outside Kits.</p>
        </div>
        <div className={`${g.maxWidth}`}>
          <h3 className={`${g.g9m} ${g.g6l} ${g.center}`}><strong>How People View Kits</strong></h3>
        </div>
        <figure className={`${g.gMarginTopSmall}`}>
          <HorizontalScroll>
            <div className={`${g.g3Max} ${g.textCenter} ${g.gNoMarginTop} ${g.gMarginLeftSmallest}`}>
              <p>All Classes</p>
              <div className={`${g.gMarginTopSmall} ${g.thrashPreventerSquare} `} >
                <img src={flowAllKits} className={`${g.gPositionAbsolute}`} />
              </div>
            </div>
            <div className={`${g.textCenter} ${g.gMarginLeftSmallest}`}>
              <img src={flowArrow} />
            </div>
            <div className={`${g.g3Max} ${g.textCenter} ${g.gNoMarginTop} ${g.gMarginLeftSmallest}`}>
              <p>Single Kit</p>
              <div className={`${g.gMarginTopSmall} ${g.thrashPreventerSquare} `} >
                <img src={flowSingleKit} className={`${g.gPositionAbsolute}`}  />
              </div>
            </div>
            <div className={`${g.textCenter} ${g.gMarginLeftSmallest}`}>
              <img src={flowArrow} />
            </div>
            <div className={`${g.g3Max} ${g.textCenter} ${g.gNoMarginTop} ${g.gMarginLeftSmallest}`}>
              <p>Purchase Kit</p>
              <div className={`${g.gMarginTopSmall} ${s.overlayRed} ${g.thrashPreventerSquare} `} >
                <img src={flowSingleKit} className={`${g.gPositionAbsolute}`} />
              </div>
            </div>
          </HorizontalScroll>
        </figure>

        <div className={`${g.maxWidth}`}>

          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>People seeking Kits may not need or want instruction; they could simply want supplies for their projects. People interested in Classes, on the other hand, seemed to also want all the supplies they need to begin learning that craft. We needed to make it easier for those viewing Classes to purchase related Kits, and we needed to convince those looking at Kits to view Classes as well.</p>

          <h2 className={`${g.g9m} ${g.g6l} ${g.center} ${g.gMarginTopLarge}`}>Alerting Users About Classes</h2>
          <p className={`${g.g9m} ${g.g6l} ${g.center} `}>For Kits that had a matching class, we added a callout that encourages users to view the class. Messaging was positioned around making sure a user’s project turned <span className={`${g.noWrap}`}>out well.</span></p>
        </div>

        <figure className={`${g.maxWidth}`}>
          <div className={`${g.gFlexContainer} ${g.gFlexEnd} ${s.kitWrapper}`}>
            <div className={`${s.wireframeKit} ${g.g9m} ${g.g7l} ${v.shadow1}`} >
              <img src={wireframeKit} />
            </div>
            <div className={`${s.calloutPanel} ${g.g7m} ${v.shadow2}`}>
               <img src={calloutPanel} />
            </div>
          </div>
          <figcaption>A callout panel that notifies users that there's a class associated with <span className={`${g.noWrap}`}>this Kit.</span></figcaption>
        </figure>


        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <h2 className={`${g.g9m} ${g.g6l} ${g.center}`}>Bundling Both Products</h2>
          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>The Class page was designed by Krystle Cho<sup>1</sup>. It allows users to purchase both kits and classes in a <span className={`${g.noWrap}`}>single click.</span></p>
          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>On both pages, we removed content from the right rail so that only the add-to-cart <span className={`${g.noWrap}`}>module remained.</span></p>
        </div>

        <figure className={`${g.maxWidth}`}>
          <div className={`${g.gFlexContainer} ${g.gFlexStart} ${s.classWrapper}`}>
            <div className={`${s.wireframeClass} ${g.g9m} ${g.g7l} ${v.shadow1}`} >
              <img src={wireframeClass} />
            </div>
            <div className={`${s.addToCartPanel} ${g.g6m} ${g.g4l} ${g.gAlignSelfCenter} ${g.z1} ${v.shadow2}`}>
              <img src={addToCartPanel} />
            </div>
          </div>
          <figcaption>A new add-to-cart module that allows for purchasing <span className={`${g.noWrap}`}>both products.</span></figcaption>
        </figure>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <h2 className={`${g.g9m} ${g.g6l} ${g.center}`}>User Testing</h2>
          <p className={`${g.g9m} ${g.g6l} ${g.center}`}> This was a clear direction, but we still needed to validate it with users, so I conducted a round of in-person user tests with 5 people.</p>

          <blockquote className={`${g.g5l} ${g.center} ${g.floatRightM}`}>“Okay, Class and Kit… well that’s confusing, because it looks like it’s <span className={`${g.noWrap}`}>a price</span> range, not <span className={`${g.noWrap}`}>a choice.</span>”
          </blockquote>

          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>The results showed we still needed to communicate our pricing structure more effectively. For instance, in the first user test below, Sophie couldn't understand the price range until she selected the drop down menu.</p>

          <p className={`${g.g9m} ${g.g6l} ${g.center}`}> While I reported these findings to the team, Krystle revised the class page to better communicate the pricing structure. We tested again using a toggle instead of a dropdown menu, with much better results.</p>

        </div>

        <figure className={`${g.maxWidth}`}>
          <div className={`${g.gFlexContainer} ${g.gFlexCenter} ${s.userTestingWrapper}`}>
            <video className={`${g.g5m}`} autoPlay playsInline loop muted poster="http://placehold.it/20x20/">
              <source src={userTestWebm} type="video/webm" />
              <source src={userTestMp4} type="video/mp4" />
            </video>
            <Iphone image={iphoneImage} className={`${g.g4m}`} />
          </div>
          <figcaption className={`${g.textCenter}`}>On the left, user testing the initial design. The revised design <span className={`${g.noWrap}`}>on right.</span></figcaption>
        </figure>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <p className={`${g.g9m} ${g.g9m} ${g.g6l} ${g.center}`}>Simplifying the product pages and removing friction to purchase both the class and kit increased the attachment rate by 3.5%. We did it without inhibiting new strategy exploration for the rest of the  team, and we saved engineering resources  by building and deploying our own  prototype.</p>

          <h2 className={`${g.g9m} ${g.g6l} ${g.center}`}>Credits</h2>

          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>
            <LinkExternal href="https://www.linkedin.com/in/ericarios">Erica Rios</LinkExternal> – Project Manager <br />
            <LinkExternal href="https://angel.co/mskrys" >Krystle Cho</LinkExternal> – Product Designer <br />
            <LinkExternal href="https://twitter.com/monokrome">Bailey Stoner</LinkExternal> – Engineer
          </p>
        </div>
      </Layout>
    );
  }

}

export default ImprovingPurchaseProcessPage;
