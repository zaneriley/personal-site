import React, { PropTypes } from 'react';
import cx from 'classnames';
import Link from '../Link';
import v from '../../src/styles/variables.css';
import g from '../../src/styles/grid.css';
import z from '../../src/styles/aesthetics.css';
import s from './BreadCrumbs.css';


class BreadCrumbs extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    pageLocation: PropTypes.string,
  };

  render() {

    const { className, pageLocation } = this.props;

    return ( 

      <nav role="navigation" className={cx(s.breadcrumbs, className) + ``}>
        <ol id="breadcrumb" aria-label="You are here:">
          <small>
            <li><Link to="/" title="Home">Home</Link></li>
            <li>{pageLocation}</li>
          </small>
        </ol>
      </nav>

    );
  }
  
}
export default BreadCrumbs;