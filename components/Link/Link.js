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
import history from '../../src/history';
import b from '../../src/main.css';
import s from './Link.css';

class Link extends React.Component {

  static propTypes = {
    to: PropTypes.oneOfType([PropTypes.string, PropTypes.object]).isRequired,
    onClick: PropTypes.func,
    childWrapper: PropTypes.bool
  };

  static defaultProps = {
    childWrapper: true,
  };


  handleClick = (event) => {
    if (this.props.onClick) {
      this.props.onClick(event);
    }

    if (event.button !== 0 /* left click */) {
      return;
    }

    if (event.metaKey || event.altKey || event.ctrlKey || event.shiftKey) {
      return;
    }

    if (event.defaultPrevented === true) {
      return;
    }

    event.preventDefault();

    if (this.props.to) {
      history.push(this.props.to);    
    } else {
      history.push({
        pathname: event.currentTarget.pathname,
        search: event.currentTarget.search,
      });
    }
  };

  render() {
    const { to, children, childWrapper, ...props } = this.props;

    function getChildrenWithContainer() {
      if (!childWrapper) return children;
      return <span className={`${s.linkText}`}>{ children }</span>;
    }

    return (
      <a href={typeof to === 'string' ? to : history.createHref(to)} {...props} onClick={this.handleClick} >{ getChildrenWithContainer() }</a>
    );
  }

}

export default Link;
