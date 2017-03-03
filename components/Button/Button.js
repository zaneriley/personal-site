/**
 * React Static Boilerplate
 * https://github.com/kriasoft/react-static-boilerplate
 *
 * Copyright © 2015-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { PropTypes } from 'react';
import cx from 'classnames';
import Link from '../Link';
import s from './Button.css';

class Button extends React.Component {

  static propTypes = {
    component: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.element,
      PropTypes.func,
    ]),
    to: PropTypes.oneOfType([PropTypes.string, PropTypes.object]),
    href: PropTypes.string,
    className: PropTypes.string,
  };

  render() {
    const { component, type, className, to, href, children, ...other } = this.props;

    return React.createElement(
      component || to ? Link : (href ? 'a' : 'button'), 
      {
        ref: node => (this.root = node),
        className: cx(className, s.button), to, href, ...other,
        childWrapper: false,
        href: to,
      },
      children
    );
  }

}

export default Button;
