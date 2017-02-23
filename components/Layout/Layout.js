
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
import cx from 'classnames';
import ReactCSSTransitionGroup from 'react-addons-css-transition-group'
import Footer from '../Footer';
import Header from '../Header';
import BigNav from '../BigNav';
import s from './Layout.css';
import g from '../../src/styles/grid.css';
import z from '../../src/styles/aesthetics.css';

class Layout extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };

  componentDidMount() {
    window.componentHandler.upgradeElement(this.root);
  }

  componentWillUnmount() {
    window.componentHandler.downgradeElements(this.root);
  }

  render() {
    const { path, children, className } = this.props;

    return (
      <ReactCSSTransitionGroup
      component="div"
      className="container"
      transitionName={{
        enter: s.enter,
        leave: s.leave
      }}
      transitionEnterTimeout={9000}
      transitionLeaveTimeout={9000}
      >
        <div className="mdl-layout mdl-js-layout" ref={node => (this.root = node)}>
          <BigNav />
          <div className={`mdl-layout__inner-container`}>
            <Header />
            <main className={`mdl-layout__content`}>
              <div className={`${s.sitePrevious} ${g.maxWidthOuter} ${z.shadow1} ${z.borderRadiusTop}`} />
              <section className={`${s.siteContent} ${g.maxWidthOuter} ${z.shadow2} ${z.borderRadiusTop}`}>
                <div {...this.props} className={cx(s.content, className) + ``} />
              </section>
              <Footer />
            </main>
          </div>
        </div>
      </ReactCSSTransitionGroup>
    );
  }
  
}
export default Layout;
