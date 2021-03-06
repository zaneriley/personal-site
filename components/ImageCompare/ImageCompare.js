import React, { PropTypes } from 'react';
import cx from 'classnames';
import { Resizable, ResizableBox } from 'react-resizable';
import v from '../../src/styles/variables.css';
import g from '../../src/styles/grid.css';
import z from '../../src/styles/aesthetics.css';
import s from './ImageCompare.css';
import IconChromeBar from '../IconChromeBar';

type State = {width: string};
type Size = {width: number};
type ResizeData = {element: Element, size: Size};

class ImageCompare extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    before: PropTypes.object,
    after: PropTypes.object,
  };

  state = {width: 200, height: 200};

  onResize = (event, {element, size}) => {
    this.setState({width: size.width});
    this.setState({height: size.height});
  };

  render() {

    const { className, before, after } = this.props;

    return ( 

      <div className={cx(z.shadow1, z.borderRadiusTop, className) + ``}>
        <IconChromeBar />
        <div className={`${s.ImageCompareWrapper} ${g.gNoMarginTop}`}>
            <div className={`${s.baseImage}`}>
              <a href={after.url} target="_blank">
                <img src={after.placeholder} srcSet={after.images} alt={after.alt} />
              </a>
            </div>

            <Resizable width={this.state.width} height={this.state.height} axis="x" onResize={this.onResize} className={`${g.gNoMarginTop}`}>
              <div style={{width: this.state.width + 'px'}}>
                <div className={`${s.crop}`}>
                  <img className={`${s.noCrop}`} src={before.placeholder} srcSet={before.images} alt={before.alt}/>
                </div>
              </div>
            </Resizable>
        </div>
      </div>
    );
  }
  
}
export default ImageCompare;