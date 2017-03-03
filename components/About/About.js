import React, { PropTypes } from 'react';
import cx from 'classnames';
import IconClock from '../IconClock';
import Button from '../Button';
import g from '../../src/styles/grid.css';


class About extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    title: PropTypes.string,
    about: PropTypes.string,
    role: PropTypes.string,
    result: PropTypes.string,
    readingLength: PropTypes.string,
  };

  render() {
    const { title, about, role, result } = this.props;
    
    const readingLength = this.props.readingLength || '3 Minute Read'

    return (
      <div className={`${g.maxWidth}`}>

        <h1 dangerouslySetInnerHTML={{__html: title}} />

        <div className={`${g.gFlexContainer}`}>
          <div className={` ${g.g12m} ${g.g6l} `}>
            <h2>About Project</h2>
            <p>{about}</p>
          </div>

          <div className={` ${g.g6m} ${g.g3l} ${g.gMarginLeftL} ${g.gNoMarginTopL}`}>
            <h2>Role</h2>
            <p>{role}</p>
          </div>

          <div className={` ${g.g6m} ${g.g3l} ${g.gMarginLeftM} ${g.gNoMarginTopL}`}>
            <h2>Results</h2>
            <p dangerouslySetInnerHTML={{__html: result}}></p>
          </div>
        </div>
  
        <div>
          <span><IconClock /> {readingLength}</span> <button className={` ${g.gMarginLeftSmall} ${g.gNoMarginTop}`} href="#">View Gallery</button>
        </div>
      </div>
    );
  }
  
}
export default About;