import React, { PropTypes } from 'react';
import cx from 'classnames';
import Panel from '../Panel';
import IconClock from '../IconClock';
import g from '../../src/styles/grid.css';
import z from '../../src/styles/aesthetics.css';
import s from './UpNext.css';

class UpNext extends React.Component {

  static defaultProps = {
    recommendedPageFirst: {},
    recommendedPageSecond: {},
  };

  static propTypes = {
    className: PropTypes.string,
    recommendedPageFirst: PropTypes.array,
    recommendedPageSecond: PropTypes.array,
  };

  render() {

    const { className, recommendedPageFirst, recommendedPageSecond } = this.props;

    return ( 

      <div className={`${s.upNextWrapper} ${z.bgGradient}`}>

        <h2 className={`${g.maxWidth}`}>More Case Studies</h2>

        <div className={cx(g.maxWidth, g.gMarginTopSmall, g.gFlexContainer, g.gJustifySpaceBetween, g.gFlexStart, className) + ``}>

          <Panel panelPage={recommendedPageFirst} className={`${g.g6m}`} />

          <Panel panelPage={recommendedPageSecond} className={`${g.g6m}`} />

        </div>
      </div>
    );
  }
  
}
export default UpNext;