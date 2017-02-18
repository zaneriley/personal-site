import React, { PropTypes } from 'react';
import cx from 'classnames';
import IconClock from '../IconClock';
import g from '../../src/styles/grid.css';
import z from '../../src/styles/aesthetics.css';
import s from './UpNext.css';

class UpNext extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };

  render() {

    const { className} = this.props;

    return ( 

      <div className={className + ` ${g.maxWidth} ${g.gFlexContainer} ${g.gJustifySpaceBetween} ${g.gMarginTopLarge}`}>
        
        <div className={`${s.panel} ${g.g6m} ${z.shadow2} ${g.gFlexContainer}`}>
          <h3>Helping people more easily find inspiration for  DIY projects.</h3>
          <div className={`${g.gAlignSelfEnd} ${g.gMarginTopSmall} ${g.gFlexContainer} ${g.gJustifySpaceBetween}`}>
              <span>
                <IconClock /> 3 Minute Read
              </span>
              <button className={`${g.gNoMarginTop}`}>Read More</button>
          </div>
        </div>

        <div className={`${s.panel} ${g.g6m} ${z.shadow2} ${g.gNoMarginTopM} ${g.gFlexContainer}`}>
          <h3>Building a design system</h3>
          <div className={`${g.gAlignSelfEnd} ${g.gMarginTopSmall} ${g.gFlexContainer} ${g.gFlexStart} ${g.gJustifySpaceBetween}`}>
            <span>
              <IconClock /> 2 Minute Read
            </span>
            <button className={`${g.gNoMarginTop}`}>Read More</button>
          </div>
        </div>

      </div>
    );
  }
  
}
export default UpNext;