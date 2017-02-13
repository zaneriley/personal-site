import React, { PropTypes } from 'react';
import cx from 'classnames';
import s from './Iphone.css';
import g from '../../src/styles/grid.css';
import v from '../../src/styles/aesthetics.css';

class Iphone extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    image: PropTypes.string,
  };


  render() {

    const { className, image } = this.props;

    return (
      <div className={className + ` ${s.iphone} ${v.shadow2}`}>
        <div className={`${s.controls} ${s.headset}`} />
        <div className={`${s.imageWrapper}`}>
          <img src={image} className={`${g.gPositionAbsoluteL}`} />
        </div>
        <div className={`${s.controls} ${s.home}`} />
      </div>
    );
  }
  
}
export default Iphone;