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

function Footer() {
  return (
    <footer className="mdl-mini-footer">
      <div className="mdl-mini-footer__left-section">
        <div className="mdl-logo">© Company Name</div>
        <ul className="mdl-mini-footer__link-list">
          <li><Link to="/privacy">Privacy & Terms</Link></li>
          <li><Link to="/not-found">Not Found</Link></li>
        </ul>
      </div>
    </footer>
  );
}

export default Footer;
