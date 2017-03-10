import React, { PropTypes } from 'react';
import cx from 'classnames';
import LazyLoad from 'react-lazyload';
import ReactCSSTransitionGroup from 'react-addons-css-transition-group';
import s from './LazyLoad.css'
import g from '../../src/styles/grid.css';
import v from '../../src/styles/aesthetics.css';

class LazyLoader extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    height: PropTypes.string.isRequired,
    offset: PropTypes.number,
    once: PropTypes.bool,
    placeholderImage: PropTypes.string,
    placeholderColor: PropTypes.string,
  };

render() {

    const { height, placeholderImage, placeholderColor, className, children } = this.props;

    const offset = this.props.offset || 25;
    const once = this.props.once || false;

    const placeholderStyle = {
      paddingTop: height,
      backgroundColor: placeholderColor,
      backgroundImage: placeholderImage ? 'url(' + placeholderImage + ')' : '',
    }

    function PlaceholderComponent() {

      return (
        <span></span>
      );
    }

    return (
      <ReactCSSTransitionGroup
        component="div"
        className={cx(s.placeholder, g.z1, g.gPositionRelative, className) + ``}
        style={placeholderStyle}
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
        transitionEnterTimeout={500}
        transitionLeave={false}>
        <LazyLoad offset={offset} placeholder={<PlaceholderComponent key={1}/>}>
          <ReactCSSTransitionGroup
            component="div"
            className={`${g.gPositionAbsolute}`}
            key={1}
            transitionName={{
              enter: v.enter,
              enterActive: v.enterActive,
              leave: v.leave,
              leaveActive: v.leaveActive,
              appear: v.appear,
              appearActive: v.appearActive
            }}
            transitionAppear={true}
            transitionAppearTimeout={20000}
            transitionEnter={true}
            transitionEnterTimeout={20000}
            transitionLeave={true}
            transitionLeaveTimeout={20000}>
              {children}
          </ReactCSSTransitionGroup>
        </LazyLoad>
      </ReactCSSTransitionGroup>
    );
  }
  
}
export default LazyLoader;