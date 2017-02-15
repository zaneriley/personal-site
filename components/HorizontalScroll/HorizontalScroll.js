import React, { PropTypes } from 'react';
import cx from 'classnames';
import s from './HorizontalScroll.css';

class HorizontalScroll extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };

  render() {

    const { className } = this.props;

    return ( 

      <div className={className + ` ${s.horizontalScrollOuterWrapper}`}>
        <div className={`${s.horizontalScrollInnerWrapper}`}>
          {this.props.children}
        </div>
      </div>
    );
  }
  
}
export default HorizontalScroll;