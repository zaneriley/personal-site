/**
 * React Static Boilerplate
 * https://github.com/kriasoft/react-static-boilerplate
 *
 * Copyright © 2015-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import Link from '../Link';
import LinkExternal from '../LinkExternal';
import g from '../../src/styles/grid.css';
import s from './Footer.css';

import iconDribbble from '../../src/assets/images/dribbble.svg';
import iconGithub from '../../src/assets/images/github.svg';
import iconCodepen from '../../src/assets/images/codepen.svg';
import iconTwitter from '../../src/assets/images/twitter.svg';
import iconAngellist from '../../src/assets/images/angellist.svg';
import iconLinkedIn from '../../src/assets/images/linkedin.svg';

function Footer() {
  return (
    <footer className={`${g.gMarginTopLarge}`}>
      <div className={`${g.maxWidth}`}>
          <h2 className={`${g.g9m} ${g.g6l} ${s.mail}`}><a href="mailto:hello@zaneriley.com">hello@zaneriley.com</a></h2>
          <p className={`${s.socialIcons} ${g.g9m} ${g.g6l}`}>
           <a href="http://dribbble.com/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank"><img src={iconDribbble} alt="Zane's Dribbbble Profile" /></a> 
           <a href="http://github.com/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank"><img src={iconGithub} alt="Zane's Github Profile" /></a> 
           <a href="http://codepen.io/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank"><img src={iconCodepen} alt="Zane's Codepen Profile" /></a> 
           <a href="http://twitter.com/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank"><img src={iconTwitter} alt="Zane's Twitter Profile" /></a> 
           <a href="http://angellist.com/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank"><img src={iconAngellist} alt="Zane's Angellist Profile" /></a> 
           <a href="https://www.linkedin.com/in/zaneriley" className={`${g.gMarginLeftSmaller}`} target="_blank"><img src={iconLinkedIn} alt="Zane's LinkedIn Profile" /></a>
          </p>
          <p className={`${g.g9m} ${g.g6l}`}>Type is set in Maria and GT America. Site built with React, Post-CSS and Webpack. View it on <LinkExternal href="https://github.com/zaneriley/personal-site">Github</LinkExternal>.</p>
          <div className={`${g.textCenter}`}>
            <p><strong>Copyright © 2014 - 2017 Zane Riley</strong></p>
          </div>
        </div>
    </footer>
  );
}

export default Footer;
