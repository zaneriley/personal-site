import React, { PropTypes } from 'react';
import cx from 'classnames';
import s from './Code.css';
import g from '../../src/styles/grid.css';
import v from '../../src/styles/aesthetics.css';

class Code extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    filename: PropTypes.string.isRequired,
  };


  render() {
    const { className, children, filename} = this.props;
    return (
      <div className={cx(v.shadow1, v.borderRadiusSmall, g.code, className) + ``}>
        <div className={`${s.header}`}>
          <small><span>{filename}</span></small>
        </div>
        <pre className={`${g.gNoMarginTop}`}>
          <code>{ children }</code>
        </pre>
      </div>
    );
  }
  
}

export default Code;