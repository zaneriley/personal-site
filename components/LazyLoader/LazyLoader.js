import React, { PropTypes } from 'react';
import cx from 'classnames';
import LazyLoad from 'react-lazyload';
import ReactCSSTransitionGroup from 'react-addons-css-transition-group';
import g from '../../src/styles/grid.css';
import v from '../../src/styles/aesthetics.css';

class LazyLoader extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    placeholderImage: PropTypes.string,
    height: PropTypes.string,
  };

render() {

    const { height, placeholderImage, children } = this.props;

    return (

      <Lazyload height={height} className={cx(s.content, g.gMarginTopSmaller) + ``}>

            <ReactCSSTransitionGroup key="1"
              transitionName={{
                enter: v.enter,
                enterActive: v.enterActive,
                leave: v.leave,
                leaveActive: v.leaveActive,
                appear: v.appear,
                appearActive: v.appearActive
              }}
              transitionAppear={true}
              transitionAppearTimeout={500}
              transitionEnter={true}
              transitionLeave={false}>

              {children}

            </ReactCSSTransitionGroup>
      </Lazyload>
    );
  }
  
}
export default LazyLoader;