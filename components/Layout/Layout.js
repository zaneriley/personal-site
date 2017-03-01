
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
    window.scrollTo(0, 0);
  }

  componentWillUnmount() {
  }

  render() {

    const { 
      path, 
      children, 
      className, 
      breadCrumbs,
      recommendedPageFirst,
      recommendedPageSecond,
      ...rest
    } = this.props;

    return (
        
        <div className={cx(className) + ` mdl-js-layout ref={node => (this.root = node)}`}>
          <Header />
          <div className={`mdl-layout__inner-container ${g.gNoMarginTop}`}>
            
            <main className={`mdl-layout__content `}>
              <section className={`${s.siteContent}`}>

              {breadCrumbs.length > 0 &&
                <BreadCrumbs pageLocation={this.props.breadCrumbs} className={`${g.maxWidth} `}/>
              }

                <div className={cx(s.content, g.gMarginTopSmaller) + ``}>
                  {children}
                </div>
              </section>

              {recommendedPageFirst.title.length > 0 && 
                <UpNext recommendedPageFirst={this.props.recommendedPageFirst} recommendedPageSecond={this.props.recommendedPageSecond}  />
              }
              <Footer />
            </main>
          </div>
        </div>
    );
  }
  
}
export default Layout;
