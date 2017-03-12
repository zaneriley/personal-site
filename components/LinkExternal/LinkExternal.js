import React, { PropTypes } from 'react';
import cx from 'classnames';
import IconExternal from '../IconExternal'
import s from './LinkExternal.css';
import g from '../../src/styles/grid.css';

class LinkExternal extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    href: PropTypes.string.isRequired
  };

  render() {

    const { className, href } = this.props;

    return (

      <a href={href} target="_blank" rel="noopener" className={cx(s.LinkExternal, className) + ``}>
        <span className={`${s.linkText}`}>{this.props.children}</span>&nbsp;
        <span className={`${s.LinkExternalIcon}`}><IconExternal /></span>
      </a>
      
    );
  }
}
export default LinkExternal;