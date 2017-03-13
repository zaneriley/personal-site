import React, { PropTypes } from 'react';
import cx from 'classnames';
import s from './HorizontalScroll.css';

class HorizontalScroll extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };

  render() {

    const { className, children } = this.props;

    return ( 

      <div className={cx(s.horizontalScrollOuterWrapper, className) + ``}>
        <div className={`${s.horizontalScrollInnerWrapper}`}>
          {children}
        </div>
      </div>
    );
  }
  
}
export default HorizontalScroll;