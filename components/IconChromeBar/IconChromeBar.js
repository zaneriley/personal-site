import React, { PropTypes } from 'react';
import cx from 'classnames';
import s from './IconChromeBar.css';
import g from '../../src/styles/grid.css';

class IconChromeBar extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };


  render() {


    return (
      <div className={`${s.bar}`}>
        <div className={`${s.circle} ${s.red} ${g.gNoMarginTop} ${g.gMarginLeftSmaller}`} />
        <div className={`${s.circle} ${s.yellow} ${g.gNoMarginTop} ${g.gMarginLeftSmaller}`} />
        <a href="#" className={`${s.circle} ${s.green} ${g.gNoMarginTop} ${g.gMarginLeftSmaller}`} />
      </div>
    );
  }
  
}
export default IconChromeBar;