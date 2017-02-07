import React, { PropTypes } from 'react';
import cx from 'classnames';
import g from '../../src/styles/grid.css';
import s from './About.css';

class About extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    title: PropTypes.string,
  };

  render() {
    return (
      <div className={`${g.maxWidth} ${s.project}`}>

        <h1 className={` ${s.title}`}>
          {this.props.title}
        </h1>

        <div className={`${g.gContainer}`}>
          <div className={` ${g.g12m} ${g.g6l} `}>
            <h2>About Project</h2>
            <p>Brit + Co helps women discover online courses and DIY tutorials to improve their creativity and embrace their passion. At the time of this project, we separately sold the supplies (“Kits”) for projects and Classes.</p>
          </div>

          <div className={` ${g.g6m} ${g.g3l} ${g.gMarginLeftL} ${g.gNoMarginTopL}`}>
            <h2>Role</h2>
            <p>Wireframing and visual design of kit page. Developed prototype and led user testing.</p>
          </div>

          <div className={` ${g.g6m} ${g.g3l} ${g.gMarginLeftM} ${g.gNoMarginTopL}`}>
            <h2>Results</h2>
            <p><strong>3.5% increase</strong> in the attach rate (the rate classes and kits were purchased together).</p>
          </div>
        </div>
      </div>
    );
  }
  
}
export default About;