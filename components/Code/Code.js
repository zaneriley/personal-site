import React, { PropTypes } from 'react';
import cx from 'classnames';
import s from './Code.css';
import g from '../../src/styles/grid.css';
import v from '../../src/styles/aesthetics.css';

class Code extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };


  render() {
    const { className, children } = this.props;
    return (
      <pre className={className + ` ${s.bar} ${v.shadow1}`}>
        <code>{ children }</code>
      </pre>
    );
  }
  
}

export default Code;