import React, { PropTypes } from 'react';
import cx from 'classnames';
import Link from '../Link';
import LinkExternal from '../LinkExternal';
import g from '../../src/styles/grid.css';
import s from './SocialIcons.css';

import iconDribbble from '../../src/assets/images/dribbble.svg';
import iconGithub from '../../src/assets/images/github.svg';
import iconCodepen from '../../src/assets/images/codepen.svg';
import iconTwitter from '../../src/assets/images/twitter.svg';
import iconAngellist from '../../src/assets/images/angellist.svg';
import iconLinkedIn from '../../src/assets/images/linkedin.svg';

class SocialIcons extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };

  render() {

    const { className } = this.props;

    return (
      <p className={className + ` ${s.socialIcons}`}>
      
        <a href="https://dribbble.com/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank" rel="noopener">
          <img src={iconDribbble} alt="Zane's Dribbbble Profile"/>
        </a> 
        
        <a href="https://github.com/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank" rel="noopener">
          <img src={iconGithub} alt="Zane's Github Profile"/>
        </a> 
        
        <a href="https://codepen.io/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank" rel="noopener">
          <img src={iconCodepen} alt="Zane's Codepen Profile"/>
        </a> 
        
        <a href="https://twitter.com/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank" rel="noopener">
          <img src={iconTwitter} alt="Zane's Twitter Profile"/>
        </a> 
        
        <a href="https://angellist.com/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank" rel="noopener">
          <img src={iconAngellist} alt="Zane's Angellist Profile"/>
        </a> 
        
        <a href="https://www.linkedin.com/in/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank" rel="noopener">
          <img src={iconLinkedIn} alt="Zane's LinkedIn Profile"/>
        </a>
      
      </p>
    );
  }
  
}
export default SocialIcons;
