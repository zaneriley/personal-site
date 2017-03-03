import React, { PropTypes } from 'react';
import cx from 'classnames';
import Link from '../Link';
import Button from '../Button';
import IconClock from '../IconClock';
import g from '../../src/styles/grid.css';
import z from '../../src/styles/aesthetics.css';
import s from './Panel.css';

class Panel extends React.Component {


  static defaultProps = {
    panelPage: {},
    type: 'small',
  };

  static propTypes = {
    className: PropTypes.string,
    panelPage: PropTypes.array,
    type: PropTypes.oneOf(['large', 'small']),
  };

  renderTypeOfPanel() {
    if (this.props.type === 'large') {

      return (

      <div className={cx(s.panel, z.shadow2, g.gFlexContainer, g.gPositionRelative, this.props.className) + ``}>
        <Link to={this.props.panelPage.path} className={`${g.gPositionAbsolute}`} />

        <h2 dangerouslySetInnerHTML={{__html: this.props.panelPage.title}} className={`${g.gNoMarginTop}`}/>

        <p>{this.props.panelPage.about}</p>

        <div className={`${g.gAlignSelfEnd} ${g.gMarginTopSmall} ${g.gFlexContainer} ${g.gJustifySpaceBetween}`}>

            <span>
              <IconClock /> {this.props.panelPage.readingLength}
            </span>

            <Button className={`${g.gNoMarginTop}`} to={this.props.panelPage.path}>Read More</Button>

        </div>
      </div>
        
      );
    } else {

      return (
         <div className={cx(s.panel, z.shadow2, g.gFlexContainer, g.gPositionRelative, this.props.className) + ``}>
          <Link to={this.props.panelPage.path} className={`${g.gPositionAbsolute}`} />

          <h3 dangerouslySetInnerHTML={{__html: this.props.panelPage.title}} className={`${g.gNoMarginTop}`}/>

          <div className={`${g.gAlignSelfEnd} ${g.gMarginTopSmall} ${g.gFlexContainer} ${g.gJustifySpaceBetween}`}>

              <span>
                <IconClock /> {this.props.panelPage.readingLength}
              </span>

              <Button component="button" className={`${g.gNoMarginTop}`} to={this.props.panelPage.path}>Read More</Button>

          </div>

        </div>
      );
    }
  }


  render() {
    return ( 
      this.renderTypeOfPanel()
    );
  }
  
}
export default Panel;