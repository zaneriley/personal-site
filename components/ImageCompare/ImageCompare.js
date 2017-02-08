import React, { PropTypes } from 'react';
import cx from 'classnames';
import { Resizable, ResizableBox } from 'react-resizable';
import v from '../../src/styles/variables.css';
import g from '../../src/styles/grid.css';
import z from '../../src/styles/shadows.css';
import s from './ImageCompare.css';
import IconChromeBar from '../IconChromeBar';

type State = {width: string};
type Size = {width: number};
type ResizeData = {element: Element, size: Size};

class ImageCompare extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    before: PropTypes.string,
    after: PropTypes.string
  };

  state = {width: 200, height: 200};

  onResize = (event, {element, size}) => {
    this.setState({width: size.width});
    this.setState({height: size.height});
  };

  render() {

    const { before, after } = this.props;

    return ( 

      <div className={`${z.shadow1} ${z.borderRadiusSmall} ${g.maxWidth} ${g.hasBackground}`}>
        <IconChromeBar />
        <figure className={`${s.ImageCompareWrapper} ${g.gNoMarginTop}`}>
            <div>
              <img src={before} />
            </div>

            <Resizable width={this.state.width} height={this.state.height} axis="x" onResize={this.onResize} className={`${g.gNoMarginTop}`}>
              <div style={{width: this.state.width + 'px'}}>
                <div className={`${s.crop}`}>
                  <img className={`${s.noCrop}`} src={after} />
                </div>
              </div>
            </Resizable>

        </figure>
      </div>
    );
  }
  
}
export default ImageCompare;