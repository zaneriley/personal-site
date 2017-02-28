import React, { PropTypes } from 'react';
import cx from 'classnames';
import s from './IconExternal.css'

class IconExternal extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };


  render() {

      const { className } = this.props;

    return (

      <svg className={cx(className) + ` hover`} version="1.1" id="Layer_1" x="0" y="0" viewBox="0 -4 23 27" enableBackground="new 0 0 20.5 22.5">
        <title>External</title>
        <rect fill="#F7E0FC" id="SVGID_1_" x="4.1" y="6.5" width="16.4" height="16"/>
        <polyline fill="none" stroke="#231F20" strokeMiterlimit="10" points="16.9 10.5 16.9 19.5 0.5 19.5 0.5 2.5 8.7 2.5 "/>
        <g>
          <polyline fill="none" stroke="#231F20" strokeMiterlimit="10" points="13.8 0.5 20 0.5 20 6.5 "/>
          <line fill="none" stroke="#231F20" strokeMiterlimit="10" x1="20" y1="0.5" x2="9.7" y2="10.5"/>
        </g>
      </svg>
      
    );
  }
  
}
export default IconExternal;