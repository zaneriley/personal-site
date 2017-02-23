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
    title: PropTypes.string,
  };

  render() {

    const { className } = this.props;

    return ( 

      <nav role="navigation" className={`${s.breadcrumbs}`}>
        <ol id="breadcrumb" aria-label="You are here:">
          <small>
            <li><Link to="/" title="Home">Home</Link></li>
            <li>Case Study</li>
          </small>
        </ol>
      </nav>

    );
  }
  
}
export default BreadCrumbs;