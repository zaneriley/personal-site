import React, { PropTypes } from 'react';
import cx from 'classnames';
import { Resizable, ResizableBox } from 'react-resizable';
import v from '../../src/styles/variables.css';
import g from '../../src/styles/grid.css';
import s from './ImageCompare.css';

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

      <figure className={`${g.maxWidth} ${g.hasBackground} ${s.ImageCompareWrapper}`}>

          <div>
            <img src={before} />
          </div>

          <Resizable width={this.state.width} height={this.state.height} axis="x" onResize={this.onResize} className={`${g.gNoMarginTop}`} draggableOpts={{bounds: "parent"}}>
            <div style={{width: this.state.width + 'px'}}>
              <div className={`${s.crop}`}>
                <img className={`${s.noCrop}`} src={after} />
              </div>
            </div>
          </Resizable>

      </figure>

    );
  }
  
}
export default ImageCompare;