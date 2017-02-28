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
import ReactCSSTransitionGroup from 'react-addons-css-transition-group';
import Layout from '../../../components/Layout';
import Link from '../../../components/Link';
import Logo from '../../../components/Logo';
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
      <Layout>

        <div className={`${s.hero} ${g.gFlexContainer} ${g.gFlexCenter}`}>

                <ReactCSSTransitionGroup
      component="div"
      className={`container ${g.maxWidth}`}
      transitionName={{
        enter: s.enter,
        leave: s.leave
      }}
      transitionEnterTimeout={9000}
      transitionLeaveTimeout={9000}
      > 

            <a key="1" href="mailto:hello@zaneriley.com?subject=Hey there">
              <h2>hello@zaneriley.com</h2>
            </a>

            <h1 key="2" className={`${g.gMarginTopSmaller} ${g.g8l} `}>Digital product designer that codes</h1>

            <p key="3" className={` ${g.g6l} ${g.gMarginTop}`}>I’m Zane, a designer based in San Francisco, California. I make products easier to use and help businesses communicate more effectively. </p>

          </ReactCSSTransitionGroup>

          <Logo className={`${s.theBigZ}`}/>
        </div>

        <div className={`${g.maxWidth}`}>
          <h2 className={`${g.g9m} ${g.g6l} `}>Case Studies</h2>

          <p className={`${g.g9m} ${g.g6l} `}><Link className="mdl-navigation__link" to="/case-study/improving-purchase-process">Improving the purchase process of Classes and Kits</Link></p>

          <p className={`${g.g9m} ${g.g6l} `}><Link className="mdl-navigation__link" to="/case-study/building-a-design-system">Building a Design system.</Link></p>

        </div>


      </Layout>
    );
  }

}

export default HomePage;
