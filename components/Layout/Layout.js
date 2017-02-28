
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
import ReactCSSTransitionGroup from 'react-addons-css-transition-group';
import Footer from '../Footer';
import Header from '../Header';
import BigNav from '../BigNav';
import BreadCrumbs from '../BreadCrumbs';
import UpNext from '../UpNext';
import s from './Layout.css';
import g from '../../src/styles/grid.css';
import z from '../../src/styles/aesthetics.css';

class Layout extends React.Component {

  static defaultProps = {
    breadCrumbs: '',
    recommendedPageFirst: {title: ''},
    recommendedPageSecond: {},
  };

  static propTypes = {
    className: PropTypes.string,
    breadCrumbs: PropTypes.string,
    recommendedPageFirst: PropTypes.array,
    recommendedPageSecond: PropTypes.array
  };

  componentDidMount() {
    window.componentHandler.upgradeElement(this.root);
  }

  componentWillUnmount() {
    window.componentHandler.downgradeElements(this.root);
  }

  render() {

    const { 
      path, 
      children, 
      className, 
      breadCrumbs,
      recommendedPageFirst,
      recommendedPageSecond
    } = this.props;

    console.log(recommendedPageFirst);

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
        <Header />
        <div className={`mdl-js-layout ${g.gNoMarginTop}`} ref={node => (this.root = node)}>
          <div className={`mdl-layout__inner-container`}>
            
            <main className={`mdl-layout__content `}>
              <section className={`${s.siteContent}`}>

              {breadCrumbs.length > 0 &&
                <BreadCrumbs pageLocation={breadCrumbs} className={`${g.maxWidth} ${g.center}`}/>
              }

                <div {...this.props} className={cx(s.content, g.gMarginTopSmaller, className) + ``} />
              </section>

              {recommendedPageFirst.title.length > 0 && 
                <UpNext recommendedPageFirst={recommendedPageFirst} recommendedPageSecond={recommendedPageSecond}  />
              }
              <Footer />
            </main>
          </div>
        </div>
      </ReactCSSTransitionGroup>
    );
  }
  
}
export default Layout;
