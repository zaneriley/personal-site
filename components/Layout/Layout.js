
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
import Footer from '../Footer';
import Header from '../Header';
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
    hasHeader: true,
  };

  static propTypes = {
    className: PropTypes.string,
    breadCrumbs: PropTypes.string,
    recommendedPageFirst: PropTypes.array,
    recommendedPageSecond: PropTypes.array,
    hasHeader: PropTypes.bool
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
      hasHeader,
      ...rest
    } = this.props;

    function ifHasHeader() {
      if (hasHeader) return <Header />;
    }

    return (
        
        <div className={cx(className)} >

          { ifHasHeader() }

          <div className={`mdl-layout__inner-container ${g.gNoMarginTop}`}>

            <main className={`mdl-layout__content `}>
              <section className={`${s.siteContent}`} ref={node => (this.root = node)}>

                {breadCrumbs.length > 0 &&
                  <BreadCrumbs pageLocation={this.props.breadCrumbs} className={`${g.maxWidth}`}/>
                }

                <div className={cx(s.content, g.gMarginTopSmaller) + ``} {...rest} >
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
