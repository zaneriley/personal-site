import React, { PropTypes } from 'react';
import cx from 'classnames';
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

      <div className={`${s.upNextWrapper}`}>
        <div className={cx(g.maxWidth, g.gFlexContainer, g.gJustifySpaceBetween, g.gMarginTopLarge, className) + ``}>
          
          <div className={`${s.panel} ${g.g6m} ${z.shadow2} ${g.gFlexContainer}`}>
            <h3>{recommendedPageFirst.title}</h3>
            <div className={`${g.gAlignSelfEnd} ${g.gMarginTopSmall} ${g.gFlexContainer} ${g.gJustifySpaceBetween}`}>
                <span>
                  <IconClock /> {recommendedPageFirst.readingLength}
                </span>
                <button className={`${g.gNoMarginTop}`}>Read More</button>
            </div>
          </div>

          <div className={`${s.panel} ${g.g6m} ${z.shadow2} ${g.gNoMarginTopM} ${g.gFlexContainer}`}>
            <h3>{recommendedPageSecond.title}</h3>
            <div className={`${g.gAlignSelfEnd} ${g.gMarginTopSmall} ${g.gFlexContainer} ${g.gFlexStart} ${g.gJustifySpaceBetween}`}>
              <span>
                <IconClock /> {recommendedPageSecond.readingLength}
              </span>
              <button className={`${g.gNoMarginTop}`}>Read More</button>
            </div>
          </div>
        </div>
      </div>
    );
  }
  
}
export default UpNext;