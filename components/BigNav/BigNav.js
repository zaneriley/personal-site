import React, { PropTypes } from 'react';
import cx from 'classnames';
import BreadCrumbs from '../BreadCrumbs';
import SocialIcons from '../SocialIcons';
import v from '../../src/styles/variables.css';
import g from '../../src/styles/grid.css';
import z from '../../src/styles/aesthetics.css';
import s from './BigNav.css';

class BigNav extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };

  render() {

    const { className } = this.props;

    return ( 

      <div className={className + ` ${g.maxWidthOuter} ${g.center}`}>
        <BreadCrumbs />
        <p className={`${g.textCenter} `}>
          <a href="mailto:hello@zaneriley.com" className={`${s.bigA}`}>hello@zaneriley.com</a>
        </p>
        <SocialIcons className={`${g.textCenter} `}/>
      </div>
    );
  }
  
}
export default BigNav;