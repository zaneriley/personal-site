import React, { PropTypes } from 'react';
import cx from 'classnames';
import { Resizable, ResizableBox } from 'react-resizable';
import v from '../../src/styles/variables.css';
import g from '../../src/styles/grid.css';
import s from './ImageCompare.css';

type State = {width: string, height: number};
type Size = {width: number, height: number};
type ResizeData = {element: Element, size: Size};

class ImageCompare extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    before: PropTypes.string,
    after: PropTypes.string
  };

  state = {width: 200};

  onResize = (event, {element, size}) => {
    this.setState({width: size.width});
  };

  render() {

    const { before, after } = this.props;

    return ( 

      <figure className={`${g.maxWidth} ${g.hasBackground} ${s.ImageCompareWrapper}`}>

          <div>
            <img src={after} />
          </div>

          <Resizable width={this.state.width} axis="x" onResize={this.onResize} className={`${g.gNoMarginTop}`} draggableOpts={{bounds: "parent"}}>
            <div style={{width: this.state.width + 'px'}}>
              <div className={`${s.crop}`}>
                <img className={`${s.noCrop}`} src={before} />
              </div>
            </div>
          </Resizable>

      </figure>

    );
  }
  
}
export default ImageCompare;